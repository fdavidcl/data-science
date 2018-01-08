#!/usr/bin/env Rscript

#;--------------------- Carga de datos ---------------------
#; Función para cargar el dataset completo y las particiones
monk_load = function(filename) {
  dat = RWeka::read.arff(filename)
  dat
}

monk = monk_load("monk-2/monk-2.arff")

#;-------------------- Análisis de datos --------------------
library(dplyr)
library(ggplot2)
library(scales)
library(cowplot)
library(corrplot)

str(monk)

#; Comprobación de falta de correlación
pdf("21.pdf", width = 5, height = 5)
corrplot(cor(monk[,-7]), type = "lower", method = "square")
dev.off()

#; Incoherencia con el problema descrito
pdf("22.pdf", width = 4, height = 4)
plot(Class ~ A5, data = monk)
dev.off()

#; Deduciendo el problema MONK
monk1cl = 1 * (monk$A1 == monk$A2 | monk$A5 == 1)
monk2cl = 1 * (rowSums(monk[, 1:6] == 1) == 2)
monk3cl = 1 * ((monk$A5 == 3 & monk$A4 == 1) | (monk$A5 != 4 & monk$A2 != 3))
mean(monk$Class == monk1cl) #; => 0.5463
mean(monk$Class == monk2cl) #; => 0.4722
mean(monk$Class == monk3cl) #; => 1

#; Nivel de ruido
mean(monk$Class != monk3cl) #; => 0

#; Heatmap del dataset completo
monk2 = monk
monk2$Class = as.numeric(monk2$Class) - 1
monk2$id = 1:432
melted = reshape2::melt(monk2, id.vars = "id")
melted$value = factor(melted$value)
pdf("23.pdf", width = 5, height = 7)
ggplot(melted, aes(variable, id, fill = value)) + 
  geom_raster()
dev.off()

#; Proporciones de clases
pdf("27.pdf", width = 3, height = 5)
ggplot(monk, aes(Class, fill = Class)) + 
  geom_bar() +
  scale_fill_discrete(guide=FALSE)
dev.off()

#;===================== Clasificación =====================
#;----------------- Funciones auxiliares ------------------
acc = function(preds, truth) {
  mean(preds == truth)
}
run_fold = function(train, test, method, ...) {
  caretmethod = function(train, test) {
    model = caret::train(Class ~ ., data = train,
                         method = method,
                         preProcess = c(), ...)
    predict(model, newdata = test[, 1:6])
  }
  methods = list(
    classknn = function(train, test) {
      class::knn(train = train[, 1:6],
                 test = test[, 1:6],
                 cl = train$Class,
                 ...)
    },
    kknn = function(train, test) {
      model = kknn::kknn(Class ~ ., train, test, ...)
      model$fitted.values
    },
    knn = caretmethod,
    lda = caretmethod,
    qda = caretmethod
  )
  #; calcular predicciones y su error cuadrático medio
  c(
    train = acc(methods[[method]](train, train), train$Class),
    test  = acc(methods[[method]](train, test), test$Class)
  )
}
crossval = function(basename, folds, method = "knn", ...) {
  results = lapply(1:folds, function(i) {
    #; carga de datos
    train = monk_load(paste0(basename, "-", folds, "-", i, "tra.arff"))
    test  = monk_load(paste0(basename, "-", folds, "-", i, "tst.arff"))
    
    #; accuracy del fold
    run_fold(train, test, method, ...)
  })
  
  #; cálculo de medias
  cat("Acierto medio train:", 
      mean(sapply(results, function(x) x["train"])), "\n")
  cat("Acierto medio test: ", 
      mean(sapply(results, function(x) x["test"])), "\n")
  
  results
}

#;-------------------------- kNN --------------------------
set.seed(12345)

#; Ejecuciones de kNN con k aumentando progresivamente
allk = seq(1, 37, 2)
knnruns = data.frame(
  k = allk,
  acc =
    sapply(allk, function(k) {
      cat("Usando k =", k, "\n")
      knncv = crossval("monk-2/monk-2", 10, "classknn", k = k)
      mean(sapply(knncv, function(x) x["test"]))
    })
)
pdf("24.pdf", width = 7, height = 3.5)
plot(knnruns, type = "o", pch = 20, ylim = c(0.9, 1))
dev.off()

knnfit = crossval("monk-2/monk-2", 10, "classknn", k = 5)

#;-------------------------- LDA --------------------------
#; Comprobamos la falta de normalidad
sapply(monk[, 1:6], function(v) shapiro.test(v)$p.value)
pdf("25.pdf", width = 5, height = 5)
qqnorm(monk$A1)
qqline(monk$A1, col = "red")
dev.off()

ldafit = crossval("monk-2/monk-2", 10, "lda")

#;-------------------------- QDA --------------------------
qdafit = crossval("monk-2/monk-2", 10, "qda")

#; partition plot
pdf("26.pdf", width = 7, height = 7)
klaR::partimat(
  Class ~ A2 + A4 + A5,
  data = monk,
  method = "qda",
  plot.matrix = T
)
dev.off()

#;---------------------- Comparación ----------------------
#; Calcular los aciertos medios de cada algoritmo
results = t(as.data.frame(lapply(list(knnfit, ldafit, qdafit), function(fit) {
  c(
    train = mean(sapply(fit, function(x) x["train"])),
    test = mean(sapply(fit, function(x) x["test"]))
  )
}), col.names = c("knn", "lda", "qda")))

#; Guardar los resultados en LaTeX
sink("clas_res.tex")
knitr::kable(results, format = "latex")
sink()

res_test = read.csv("clasif_test_alumos.csv", row.names = 1)
res_train = read.csv("clasif_train_alumnos.csv", row.names = 1)

#; Guardar la tabla de test en LaTeX
sink("clas_res_all.tex")
knitr::kable(res_test, format = "latex")
sink()

#; Comparar por Friedman
friedman.test(as.matrix(res_test)) #; => p = 0.70
