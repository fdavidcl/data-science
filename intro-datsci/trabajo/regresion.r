#!/usr/bin/env Rscript

#;--------------------- Carga de datos ---------------------
#; Función para cargar el dataset completo y las particiones
abalone_load = function(filename) {
  dat = RWeka::read.arff(filename)
  dat$Sex = as.factor(dat$Sex)
  #; Correspondencia M=1, F=2, I=3 identificada mediante instancias
  #; idénticas en los datasets original y proporcionado:
  levels(dat$Sex) <- c("M", "F", "I")
  #dat$Rings = as.integer(dat$Rings)
  dat
}

abalone = abalone_load("abalone/abalone.arff")

#;-------------------- Análisis de datos --------------------
library(dplyr)
library(ggplot2)
library(scales)
library(cowplot)
library(corrplot)

#; Estructura de los datos
str(abalone)

#; Medidas de centralización y dispersión
summary(abalone)
sapply(abalone[, 2:9], sd)
Hmisc::describe(abalone)

#; Gráficos
#; edad de los individuos
pdf("11.pdf")
ggplot(abalone, aes(Rings, fill = factor(Rings))) + 
  geom_bar() +
  scale_fill_discrete(guide=FALSE)
dev.off()

#; contar el número de instancias por número de anillos y sexo
#; y construir un gráfico de barras
pdf("02.pdf")
rcplot = abalone %>% 
  group_by(Sex) %>% count(Rings) %>%
  ggplot(aes(Sex, n, fill = factor(Rings))) +
  geom_col() + 
  scale_fill_discrete(name = "Rings")
print(rcplot)
dev.off()

#; boxplot anillos respecto a sexo
pdf("01.pdf")
ggplot(abalone, aes(Sex, Rings)) + 
  geom_boxplot()
dev.off()

#; histogramas de variables numéricas
bins = c(7, 7, 5, 7, 7, 7, 7)
for (i in 2:8) {
  pdf(paste0("0", i + 1, ".pdf"), width = 5, height = 4)
  print(ggplot(abalone, aes(abalone[[i]], fill = factor(Rings))) + 
    geom_histogram(bins = bins[i - 1]) + 
    labs(x = names(abalone)[i]) +
    scale_fill_discrete(guide=FALSE))
  dev.off()
}

#; leyenda de colores
pdf("10.pdf")
ggdraw(plot_grid(NULL, get_legend(rcplot), ncol=1))
dev.off()

#; Corrplots
pdf("12.pdf", width = 5, height = 5)
corrplot(cor(abalone[, 2:9]), method = "number", type = "lower")
dev.off()

#;==================== Regresión ====================
#;-------------- Funciones auxiliares ---------------
mse = function(preds, truth) {
  sum((truth - preds) ^ 2) / length(preds)
}
run_fold = function(train, test, method = "lm", ...) {
  methods = list(
    #; modelo lineal múltiple
    lm = function(train, test) {
      model = lm(Rings ~ ., data = train, ...)
      predict(model, test)
    },
    #; kNN
    knn = function(train, test) {
      model = kknn::kknn(Rings ~ ., train, test, ...)
      model$fitted.values
    }
  )
  
  #; calcular predicciones y su error cuadrático medio
  c(
    train = mse(methods[[method]](train, train), train$Rings),
    test  = mse(methods[[method]](train, test), test$Rings)
  )
}
crossval = function(basename, folds, method = "lm", ...) {
  results = lapply(1:folds, function(i) {
    #; carga de datos
    train = abalone_load(paste0(basename, "-", folds, "-", i, "tra.arff"))
    test  = abalone_load(paste0(basename, "-", folds, "-", i, "tst.arff"))
    
    #; errores del fold
    run_fold(train, test, method, ...)
  })
  
  #; cálculo de medias
  cat("Error medio train:", 
      mean(sapply(results, function(x) x["train"])), "\n")
  cat("Error medio test: ", 
      mean(sapply(results, function(x) x["test"])), "\n")
  
  results
}

#;----------------- Modelo lineal simple -----------------
lmfit = list()
lmfit[[1]] = lm(Rings ~ Sex, data = abalone)
lmfit[[2]] = lm(Rings ~ Diameter, data = abalone)
lmfit[[3]] = lm(Rings ~ Height, data = abalone)
lmfit[[4]] = lm(Rings ~ Whole_weight, data = abalone)
lmfit[[5]] = lm(Rings ~ Shell_weight, data = abalone)
lapply(lmfit, summary)

pdf("13.pdf")
plot(Rings ~ Shell_weight, data = abalone, pch = 20)
abline(lmfit[[5]], col = "red")
dev.off()

#;----------------- Modelo lineal múltiple -----------------
multfit = lm(Rings ~ ., data = abalone)
summary(multfit)

multfit2 = lm(Rings ~ Diameter + Shucked_weight + Shell_weight, 
              data = abalone)
summary(multfit2)

#; Otros intentos: no linealidad, interacciones
multfit3 = lm(Rings ~ Length * Diameter * Height, 
              data = abalone)
summary(multfit3)

multfit4 = lm(Rings ~ Diameter * Height + 
                Sex * Shucked_weight + Shell_weight,
              data = abalone)
summary(multfit4)

#;----------------------- kNN -----------------------
set.seed(12345)
knncv = crossval("abalone/abalone", 5, "knn")

#; Varias ejecuciones de kNN
allk = seq(1, 37, 2)
knnruns = data.frame(
  k = allk,
  mse =
    sapply(allk, function(k) {
      cat("Usando k =", k, "\n")
      knncv = crossval("abalone/abalone", 5, "knn", k = k)
      mean(sapply(knncv, function(x) x["test"]))
    })
)
pdf("14.pdf", width = 5, height = 5)
plot(knnruns, type = "o", pch = 20, ylim = c(0, 9))
dev.off()

#;-------------------- Comparación --------------------
lmfit = crossval("abalone/abalone", 5)
knnfit = crossval("abalone/abalone", 5, "knn")

res_test = read.csv("regr_test_alumnos.csv", row.names = 1)
res_train = read.csv("regr_train_alumnos.csv", row.names = 1)

#; guardo tabla de resultados en LaTeX
sink("res_test.tex")
knitr::kable(
  res_test, format = "latex", 
  format.args = list(scientific = FALSE, drop0trailing = T))
sink()

#; función que realiza un test de Wilcoxon
wilcoxon = function(other, ref) {
  difs = (other - ref) / other
  wilc_1_2 = cbind(ifelse (difs < 0, abs(difs) + 0.1, 0 + 0.1),
                   ifelse (difs > 0, abs(difs) + 0.1, 0 + 0.1))
  the_test = wilcox.test(wilc_1_2[, 1],
                         wilc_1_2[, 2],
                         alternative = "two.sided",
                         paired = TRUE)
  inv_test = wilcox.test(wilc_1_2[, 2],
                         wilc_1_2[, 1],
                         alternative = "two.sided",
                         paired = TRUE)
  c(
    Rmas = the_test$statistic,
    Rmenos = inv_test$statistic,
    pvalue = the_test$p.value
  )
}

#; Aplicar el test a LM y kNN
wilcoxon(res_test[, 1], res_test[, 2])

#; Aplicar Friedman para comparación múltiple
friedman.test(as.matrix(res_test))

#; Aplicar test post-hoc de Holm
tam <- dim(res_test)
groups <- rep(1:tam[2], each=tam[1])
pairwise.wilcox.test(as.matrix(res_test),
                     groups,
                     p.adjust = "holm",
                     paired = TRUE)

