# -------------------------------------------------------------
# modelo para estimacion de cargos por asegurados
# -------------------------------------------------------------

trainclaims=read.csv('train_claims.csv')
tclaims=read.csv('test_claims.csv')

library(ggplot2)
library(dplyr)
library(caret)       
library(corrplot)    
library(xgboost)
library(tidyr)
library(SHAPforxgboost)

#exploracion de variables
str(trainclaims)


trainclaims=transform(trainclaims, sex=as.factor(sex), children=as.factor(children), smoker=as.factor(smoker), region=as.factor(region))
tclaims=transform(tclaims, sex=as.factor(sex), children=as.factor(children), smoker=as.factor(smoker), region=as.factor(region))
catcols=c('sex', 'children', 'smoker', 'region')



trainclaims=trainclaims
tclaims=tclaims

# --------------------------------------------------------Boxplots de variables categoricas
trainclaims %>%
  pivot_longer(cols = all_of(catcols), names_to = 'Variable', values_to = 'Value') %>%
  ggplot(aes(x = charges, y = Value, fill = Value)) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~ Variable, scales = 'free_y') +
  theme_minimal() +
  labs(title = 'Boxplots de variables con respecto a charges')
# se puede notar que los hombres en promedio cobran lo mismo, pero con mayor variacion, los fumadores cobranmucho mas
#la region 2 tiene mayor variacion junto con la 0 y en promedio 0 hijos cobra mas pero tiene mas outliers.
#los hijos cobranmas cuando son 3-4, pero 3 y 2 son los mas variables.

catvars=lm(charges~sex+children+smoker+region, trainclaims)
summary(catvars)



#segun el resultado de esta regresion, se puede notar que el ser fumador es muy relevante a cuanto se paga
#tambien a nivel de hijos, se puede decir que se paga mas si se tienen hijos, para 5 hijos no parece mantenrse, 
#pero se puede deber a una muestra menor, en promedio.
#la region dos parece tener una mayor probabilidad de pago, aunque este aumento no parece ser significativo
#y a nivel de genero parece que ser hombre reduce la cantidad de pagos, pero esto tampoco es significativo
#en resumen los que reclaman mayores montos son fumadores, con 2-4 hijos de la region 2


#------------------------------------------------------ exploracion de varaibles numericas
numvars=lm(charges~bmi+ age, trainclaims )
summary(numvars)

#ambas variables parecen relevantes, son estadisticamente significativas y en promedio parecen 
#porcada 1% aumentar el cargo en 336.73 para BMI  y 239 para la edad.





#-----------------------------------------------------------------creemos modelo xgboost
set.seed(777)

#-----------------------Definir datos de test y train
train=trainclaims
test=tclaims

trainm=model.matrix(charges~.-1, data = trainclaims)
testm=model.matrix(charges~.-1, data = tclaims)

xgbtrain=xgb.DMatrix(data=trainm[,3:ncol(trainm)], label=train$charges)
xgbtest=xgb.DMatrix(data=testm[,3:ncol(testm)], label=test$charges)
str(test)

#-----------------------configuracion grid hiperparametros de xgboost para optimizacion

grid=expand.grid(
  nrounds=c(70, 100, 120),
  eta=c(0.01,0.1,0.3),
  max_depth=c(3,5,7), 
  gamma=c(0,1), 
  colsample_bytree=c(0.5, 0.7), 
  min_child_weight=c(1,3,5), 
  subsample=c(0.5,0.7)
)

#----------------------configurar el control para train que establece los kfolds
train_control=trainControl(
  method='cv', 
  number = 5, 
  verboseIter = TRUE 
)

#---------entrenar el modelo XGBOOST con la optimizacion de hiper parametros

xgb_train= train(
  x=trainm,
  y=train$charges,
  trControl=train_control,
  tuneGrid=grid,
  method='xgbTree',
  metric= 'RMSE'
)

#--------------------------------extraer el mejor modelo
bestmodel=xgb_train$bestTune
bestmodel

#metricas optenidas por el mejor modelo
#nrounds = 70; max_depth=3; eta=0.1; gamma=1; colsample_ bytree= 0.7; 
#min_child_weight=5; subsample=0.5

# se hacen 70 rondas,la cantidad optima es de 70 arboles
#los arboles se ramifican menos
#las arboles aprenden 10% de los errores segun ETA
#gamma 1 por lo que se exige reduccion de errores para ramificar el arbol
#cada arbol toma una muestra de 70% de cada columna
#min child weight de 5 implica que deben existir al menos 5 obs. para crear un nuevo nodo hijo
#sumsample 50%, toma la mitad de las filas al construir el arbol


#--crear un modelo con los hiperparametros optimos, dados por el BEST TUNE:
modelo_fin=xgb.train(
  params = list(
    booster='gbtree',
    objective='reg:squarederror',
    eta=bestmodel$eta,
    max_depth=bestmodel$max_depth,
    gama=bestmodel$gamma,
    colsample_bytree=bestmodel$colsample_bytree,
    min_child_weight=bestmodel$min_child_weight,
    subsample=bestmodel$subsample
  ),
  data = xgbtrain,
  nrounds = bestmodel$nrounds,
  watchlist = list(train=xgbtrain, test=xgbtest),
  early_stopping_rounds = 30
)

#-----predecir en test
pred=predict(modelo_fin, newdata=xgbtest)
test$preds=pred


#calcular R cuadrado y rmse
rsq=cor(test$charges, pred)^2
rsq
#auque el 81% de la variacion en los cargos esta explicada por las variables en el modelo

rmse=sqrt(mean((test$charges-pred)^2))
rmse
#la desviacion del error es de $5000 aprx, para los cargos

#ver importancia de cariables
importancia=xgb.importance(feature_names = colnames(trainm[,3:ncol(trainm)]), model=modelo_fin)

importancia

xgb.plot.importance(importancia)
#las variables mas importantes como se encontro en la exploracion son
#fumador, bmi, edad y en mucho menor manera hijos.

#grafica de residuos
residuos= test$charges - pred
residuos

ggplot()+
  geom_point(aes(x=pred, y= residuos))+
  geom_hline(yintercept = 0, linetype='dashed', color='red')
mean(residuos)
#el modelo subestima los cargos en promedio, esto porque hay bastnates outliers

mean(test$charges)
mean(pred)

ggplot(test, aes(x = region, y = preds, fill = region)) +
  geom_col(show.legend = FALSE) +
  scale_fill_brewer(palette = 'Blues') +
  scale_y_continuous(labels = scales::comma)+
    labs(
    title = 'Predicted Total Payout by Region',
    x     = 'Region',
    y     = 'Total Predicted Charges'
  ) +
  theme_minimal()
#la region 2 es donde se espera pagar mas seguido de la region 3.


#preparar datos para exportar
test=test[,c(2,ncol(test))]
test
test=transform(test, charges=preds)
test=test[,c(1,3)]


#exportar datos
write.csv(test, 'predicciones.csv',row.names = FALSE)


