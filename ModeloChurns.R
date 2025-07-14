library(tidyverse)
library(caret)
library(MLmetrics)
library(gbm)
library(scales)
library(dplyr)

# cargar datos
trainChurn = read_csv('train_churn.csv')
testChurn  = read_csv('test_churn.csv')

# preprocesamiento
trainChurn = trainChurn %>%
  mutate(Exited = factor(if_else(Exited == 1, 'Yes', 'No'), levels = c('No','Yes')))
catVars = c('Geography','Gender')
trainChurn = trainChurn %>% mutate(across(all_of(catVars), as.factor))
testChurn  = testChurn  %>% mutate(across(all_of(catVars), as.factor))

# generar formula con todas las variables predictoras
dropVars      = c('RowNumber','CustomerId','Surname','Exited')
allPredictors = setdiff(names(trainChurn), dropVars)
modelFormula  = as.formula(paste('Exited ~', paste(allPredictors, collapse = ' + ')))

# dividir datos en entrenamiento y validacion
set.seed(123)
splitIndex = createDataPartition(trainChurn$Exited, p = 0.8, list = FALSE)
trainSplit  = trainChurn[splitIndex, ]
validSplit  = trainChurn[-splitIndex, ]

# funcion de resumen para F1
f1Summary = function(data, lev = NULL, model = NULL) {
  f1 = F1_Score(y_true = data$obs, y_pred = data$pred, positive = lev[2])
  c(F1 = f1)
}

# control de validacion cruzada optimizado para F1
ctrl = trainControl(
  method          = 'cv',
  number          = 5,
  summaryFunction = f1Summary,
  classProbs      = FALSE,
  savePredictions = 'final'
)

# entrenar modelos
rfModel = train(
  modelFormula,
  data       = trainSplit,
  method     = 'rf',
  metric     = 'F1',
  trControl  = ctrl,
  tuneLength = 3
)

gbmModel = train(
  modelFormula,
  data       = trainSplit,
  method     = 'gbm',
  metric     = 'F1',
  trControl  = ctrl,
  verbose    = FALSE,
  tuneLength = 3
)

# comparar resultados en validacion cruzada
resamps = resamples(list(RandomForest = rfModel, GBM = gbmModel))
print(summary(resamps, metric = 'F1'))
bwplot(resamps, metric = 'F1', main = 'Distribucion de F1 en validacion cruzada')

# evaluar en conjunto de validacion
predValidRf  = predict(rfModel, validSplit)
cmRf         = confusionMatrix(predValidRf, validSplit$Exited, positive = 'Yes')
predValidGbm = predict(gbmModel, validSplit)
cmGbm        = confusionMatrix(predValidGbm, validSplit$Exited, positive = 'Yes')

# comparar F1 en CV vs validacion para detectar overfitting
cvF1Rf   = max(rfModel$results$F1)
cvF1Gbm  = max(gbmModel$results$F1)
valF1Rf  = cmRf$byClass['F1']
valF1Gbm = cmGbm$byClass['F1']
f1Comparison = tibble(
  modelo       = c('RandomForest','GBM'),
  f1Cv         = c(cvF1Rf, cvF1Gbm),
  f1Validacion = c(valF1Rf, valF1Gbm)
)
print(f1Comparison)

# seleccionar mejor modelo segun F1 en validacion
bestModelName = f1Comparison %>%
  slice_max(f1Validacion) %>%
  pull(modelo)
bestModel = if (bestModelName == 'GBM') gbmModel else rfModel

# reentrenar mejor modelo con todos los datos de train
finalModel = train(
  modelFormula,
  data       = trainChurn,
  method     = bestModel$method,
  metric     = 'F1',
  trControl  = ctrl,
  tuneGrid   = bestModel$bestTune,
  verbose    = FALSE
)

# predecir en test_churn
testPred = predict(finalModel, testChurn)

# calcular cuantos clientes cancelan
numChurn = sum(testPred == 'Yes')
cat('Clientes esperados que cancelan:', numChurn, '\n')

# grafico de distribucion de churn predicho
tibble(prediccion = testPred) %>%
  ggplot(aes(x = prediccion, fill = prediccion)) +
  geom_bar(show.legend = FALSE) +
  labs(
    title = 'Distribucion de churn predicho',
    x     = 'Exited',
    y     = 'Cantidad'
  ) +
  theme_minimal()

# obtener importancia de variables del modelo final
impDf = varImp(finalModel)$importance %>%
  rownames_to_column('variable') %>%
  arrange(desc(Overall))

# mostrar tabla de importancia
print(impDf)

# grafico de importancia de variables
ggplot(impDf, aes(x = reorder(variable, Overall), y = Overall)) +
  geom_col(fill = 'steelblue') +
  coord_flip() +
  labs(
    title = 'Importancia de variables en el modelo',
    x     = NULL,
    y     = 'Importancia (Overall)'
  ) +
  theme_minimal()


# grafico de churn predicho
df_pred <- tibble(prediccion = testPred) %>%
  count(prediccion) %>%
  mutate(porcentaje = n / sum(n))

ggplot(df_pred, aes(x = prediccion, y = n, fill = prediccion)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = paste0(n, " (", percent(porcentaje, accuracy = 0.1), ")")),
            vjust = -0.5, size = 4) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Distribución de churn predicho",
    x = "Churn Predicho",
    y = "Cantidad de Clientes",
    fill = "Predicción"
  ) +
  theme_minimal() +
  theme(
    plot.title       = element_text(face = "bold", size = 14, hjust = 0.5),
    axis.title       = element_text(size = 12),
    axis.text        = element_text(size = 11),
    panel.grid.major.x = element_blank()
  )

# guardar archivo de submission
submission = testChurn %>% select(CustomerId) %>% mutate(Exited = testPred)
write_csv(submission, 'submission_churn.csv')

# Mostrar los hiperparámetros del modelo final
print(finalModel$bestTune)


