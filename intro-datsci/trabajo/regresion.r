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
abalone %>% 
  group_by(Sex) %>% count(Rings) %>%
  ggplot(aes(Sex, n, fill = factor(Rings))) +
  geom_col() + 
  scale_fill_discrete(name = "Rings")
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

#;-------------------- Regresión --------------------
#; Modelo lineal simple

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

#; Modelo lineal múltiple

multfit = lm(Rings ~ ., data = abalone)
summary(multfit)

multfit2 = lm(Rings ~ Diameter + Shucked_weight + Shell_weight, data = abalone)
summary(multfit2)

#; kNN
library(kknn)
#; Comparación