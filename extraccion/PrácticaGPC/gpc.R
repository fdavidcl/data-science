# Dependencias del guion --------------------------------------------
install <- function(pkg) {
  if (!(pkg %in% installed.packages())) {
    install.packages(pkg)
  }
}

install("purrr")
install("R.matlab")
install("reticulate")
install("pROC")
library(purrr)
library(reticulate)
library(pROC)

# Dependencias:
# $ pip3 install --user matplotlib
# $ pip3 install --user gpy
# Utiliza Python 3, importa GPy y matplotlib
use_python(system("which python3", intern = TRUE), required = TRUE)
gpy <- import("GPy")
plt <- import("matplotlib.pyplot")

# Extracción de los folds de entrenamiento y test normalizados ------
concatenateFolds <- function(folds, indexes, center = TRUE, scale = TRUE) {
  negative <- do.call(rbind, folds$Healthy.folds[,,indexes])
  positive <- do.call(rbind, folds$Malign.folds[,,indexes])
  
  list(
    x = scale(
      rbind(negative, positive), 
      center = center, 
      scale = scale
    ),
    y = as.matrix(c(
      rep(0, nrow(negative)),
      rep(1, nrow(positive))
    ))
  )
}

# Entrenamiento -----------------------------------------------------
set.seed(1234)

get_classifiers <- function(train_x, train_y, parts = 4, clas_f) {
  pos_ind <- which(train_y == 1)
  
  # División de las instancias negativas en 4 partes
  neg_ind <- sample(which(train_y == 0))
  # (produce warnings cuando no son exactamente del mismo tamaño)
  each_neg <- split(neg_ind, 1:parts)
  
  map(each_neg, function(neg) {
    custom_ind <- c(pos_ind, neg)
    custom_x <- train_x[custom_ind, ]
    custom_y <- train_y[custom_ind]
    
    clas_f(custom_x, as.matrix(custom_y))
  })
}

classifier_gp <- function(x, y, kernel = NULL) {
  model <- gpy$models$GPClassification(
    x, y, kernel = kernel)
  
  model$optimize(optimizer = "lbfgs", max_iters = 10000)
  #message(model)
  
  model
}

classifier_gaussian <- function(x, y) {
  # Simple way to build GP classifier with default options
  # (RBF kernel, EP interference):
  rbf <- gpy$kern$RBF(dim(x)[2], variance = 1.9, lengthscale = 1.0)
  classifier_gp(x, y)
}

classifier_linear <- function(x, y) {
  kern <- gpy$kern$Linear(dim(x)[2])
  classifier_gp(x, y, kern)
}

predictor_mean <- function(classifiers, test_x) {
  predictions <- map(classifiers, ~ .$predict(test_x)[[1]])
  rowMeans(do.call(cbind, predictions))
}

cross_validation <- function(train, test, clas_f) {
  k <- length(train)
  
  map(1:k, function(i) {
    cl <- get_classifiers(train[[i]]$x, train[[i]]$y, clas_f = clas_f)
    predictor_mean(cl, test[[i]]$x)
  })
}

measures <- function(y_true, y_pred) {
  tp <- sum(y_pred == 1 & y_pred == y_true)
  tn <- sum(y_pred == 0 & y_pred == y_true)
  
  acc <- (tp + tn) / length(y_true)
  pre <- tp / sum(y_pred == 1)
  rec <- tp / sum(y_true == 1)
  spe <- tn / sum(y_true == 0)
  
  c(
    acc = acc,
    pre = pre,
    rec = rec,
    spe = spe,
    f1 = 2 * pre * rec / (pre + rec)
  )
}

main <- function() {
  # Carga de datos ----------------------------------------------------
  folds <- R.matlab::readMat("Datos.mat")
  
  # Para cada índice concatena el resto de folds para entrenamiento
  train <- map(1:5, ~ concatenateFolds(folds, (1:5)[-.]))
  
  # Obtiene cada fold de test con la misma normalización que el 
  # correspondiente fold de train
  test <- map(
    1:5, 
    ~ concatenateFolds(
      folds,
      ., 
      center = train[[.]]$x %@% "scaled:center", 
      scale = train[[.]]$x %@% "scaled:scale"
    )
  )
  
  # Comprobación de dimensiones
  train %>% map(~ dim(.[[1]])) %>% message()
  test %>% map(~ dim(.[[1]])) %>% message()
  
  probs <- cross_validation(train, test, classifier_linear)
  preds <- map(probs, round)
  
  eval_measures <- map(1:5, ~ measures(test[[.]]$y, preds[[.]]))
  
  roc_curve <- map(1:5, ~ roc(as.integer(test[[.]]$y), probs[[.]]))
  for (i in 1:5)
    plot(roc_curve[[i]])
  
  aucs <- map(roc_curve, auc)
  confmats <- map(1:5, ~ table(true = test[[.]]$y, predicted = preds[[.]]))
}
