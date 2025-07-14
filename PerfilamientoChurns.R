# Christian Barrios
# 20210619

library(tidyverse)
library(corrplot)
library(RColorBrewer)

# Carga y transformacion
churnData = read_csv('train_churn.csv')
churnData = churnData %>%
  mutate(
    Geography       = as.factor(Geography),
    Gender          = as.factor(Gender),
    HasCrCard       = as.factor(HasCrCard),
    IsActiveMember  = as.factor(IsActiveMember),
    Exited          = as.factor(Exited)
  )

glimpse(churnData)
summary(churnData)

# NA y duplicados
missingSummary = churnData %>%
  summarise(across(everything(), ~ mean(is.na(.)))) %>%
  pivot_longer(everything(), names_to = 'variable', values_to = 'propMissing')
print(missingSummary)

numDuplicates = sum(duplicated(churnData))
print(numDuplicates)

# Distribucion de variables numéricas
numericVars = c('CreditScore','Tenure','Balance','EstimatedSalary')
churnLong = churnData %>%
  select(all_of(numericVars)) %>%
  pivot_longer(everything(), names_to = 'variable', values_to = 'value')

ggplot(churnLong, aes(x = value)) +
  geom_histogram(bins = 30, fill = 'steelblue', alpha = 0.7) +
  facet_wrap(~ variable, scales = 'free') +
  labs(
    x     = NULL,
    y     = 'Count',
    title = 'Histogramas de CreditScore, Tenure, Balance y Salario Estimado'
  ) +
  theme_minimal()

# Frecuencias de variables categoricas
catVars = c('Gender','HasCrCard','IsActiveMember','Geography')
freqTable = churnData %>%
  pivot_longer(cols = all_of(catVars), names_to = 'variable', values_to = 'value') %>%
  count(variable, value) %>%
  group_by(variable) %>%
  mutate(pct = n/sum(n)) %>%
  ungroup()

ggplot(freqTable, aes(x = factor(value), y = pct)) +
  geom_col(fill = 'salmon', alpha = 0.8) +
  geom_text(aes(label = scales::percent(pct, 0.1)), vjust = -0.5, size = 3) +
  facet_wrap(~ variable, scales = 'free_x') +
  labs(
    x     = NULL,
    y     = 'Proporcion',
    title = 'Distribucion de Género, Tarjeta de Crédito, Estado Activo y Region'
  ) +
  theme_minimal()

# Boxplots de variables numéricas según churn (abandono de clientes)
varsForBox = c('CreditScore','Tenure','Balance','EstimatedSalary')
for (v in varsForBox) {
  print(
    ggplot(churnData, aes(x = Exited, y = .data[[v]])) +
      geom_boxplot(fill = 'lightgreen', alpha = 0.7) +
      labs(
        x     = 'Churn (abandono de clientes)',
        y     = v,
        title = paste('Distribucion de', v, 'por estado de abandono de clientes')
      ) +
      theme_minimal()
  )
}

# Tasa de churn por género
churnRate = churnData %>%
  group_by(Gender, Exited) %>%
  summarise(n = n(), .groups = 'drop') %>%
  group_by(Gender) %>%
  mutate(rate = n / sum(n))

ggplot(churnRate, aes(x = Gender, y = rate, fill = Exited)) +
  geom_col(position = 'dodge', alpha = 0.8) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x     = 'Género',
    y     = 'Tasa de churn (abandono de clientes)',
    title = 'Tasa de abandono de clientes por género'
  ) +
  theme_minimal()

# Tasa de churn según posesion de tarjeta de crédito
churnRate2 = churnData %>%
  group_by(HasCrCard, Exited) %>%
  summarise(n = n(), .groups = 'drop') %>%
  group_by(HasCrCard) %>%
  mutate(rate = n / sum(n))

ggplot(churnRate2, aes(x = HasCrCard, y = rate, fill = Exited)) +
  geom_col(position = 'dodge', alpha = 0.8) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x     = 'Posee tarjeta de crédito',
    y     = 'Tasa de churn (abandono de clientes)',
    title = 'Tasa de abandono de clientes según posesion de tarjeta'
  ) +
  theme_minimal()

# Mapa de calor de correlaciones entre variables numéricas
numVars2 = c('CreditScore','Age','Tenure','Balance','NumOfProducts','EstimatedSalary')
corrMatrix = churnData %>%
  select(all_of(numVars2)) %>%
  cor(use = 'pairwise.complete.obs')
corrDF = as.data.frame(as.table(corrMatrix))
names(corrDF) = c('Var1','Var2','Correlation')

ggplot(corrDF, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile() +
  geom_text(aes(label = round(Correlation, 2)), size = 3) +
  scale_fill_gradientn(
    colors   = brewer.pal(9, 'RdBu'),
    limits   = c(-1, 1),
    name     = 'Corr'
  ) +
  labs(
    x     = NULL,
    y     = NULL,
    title = 'Mapa de calor de correlaciones entre variables numéricas'
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Distribucion de edad según churn (abandono de clientes)
ggplot(churnData, aes(x = Age, fill = Exited)) +
  geom_histogram(bins = 30, position = 'identity', alpha = 0.6) +
  labs(
    x     = 'Edad',
    y     = 'Count',
    title = 'Distribucion de edad según abandono de clientes'
  ) +
  theme_minimal()

# Densidad de edad según churn (abandono de clientes)
ggplot(churnData, aes(x = Age, fill = Exited)) +
  geom_density(alpha = 0.4) +
  labs(
    x     = 'Edad',
    y     = 'Densidad',
    title = 'Densidad de edad según abandono de clientes'
  ) +
  theme_minimal()

# Tasa de churn por region geografica
geoRate = churnData %>%
  group_by(Geography, Exited) %>%
  summarise(n = n(), .groups = 'drop') %>%
  group_by(Geography) %>%
  mutate(rate = n / sum(n))

ggplot(geoRate, aes(x = Geography, y = rate, fill = Exited)) +
  geom_col(position = 'dodge', alpha = 0.8) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x     = 'Region',
    y     = 'Tasa de churn (abandono de clientes)',
    title = 'Tasa de abandono de clientes por region geografica'
  ) +
  theme_minimal()

# Proporcion de churn por region y género
ggplot(churnData, aes(x = Geography, fill = Exited)) +
  geom_bar(position = 'fill', alpha = 0.8) +
  facet_wrap(~ Gender) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x     = 'Region',
    y     = 'Proporcion de churn (abandono de clientes)',
    title = 'Proporcion de abandono de clientes por region y género'
  ) +
  theme_minimal()


# Analisis de los graficos:

# Distribucion de edad por churn:
#    - Los clientes que churnean (Exited=1) tienden a ser mayores: pico alrededor de 45–50 años.
#    - Los que permanecen (Exited=0) tienen pico de edad en 30–40 años.
#    - Conclusion: a mayor edad, mayor probabilidad de churn.

# Tasa de churn por Geography:
#    - Germany muestra la tasa mas alta (~42% churn).
#    - France y Spain estan en torno a ~15–16%.
#    - Accion: investigar causas del churn elevado en el mercado aleman.

# Churn por Geography y Gender:
#    - En Germany, las mujeres churnean ~52% vs ~33% de los hombres.
#    - En France y Spain, mujeres ~23–24% vs hombres ~10–12%.
#    - Insight: el churn femenino es sistematicamente mayor, critico en Germany.

# Tasa de churn por Gender y HasCrCard:
#    - Mujeres churnean ~30%, hombres ~15%.
#    - Tener tarjeta de credito (HasCrCard) no altera la tasa (~21% igual).
#    - Genero es factor relevante; posesion de tarjeta no.

# Distribucion de variables categoricas:
#    - Gender: 44.4% Female, 55.6% Male.
#    - Geography: 59.9% France, 18.1% Germany, 22.0% Spain.
#    - HasCrCard: 78.3% tienen tarjeta.
#    - IsActiveMember: 50.6% activos vs 49.4% inactivos.
#    - Estos desbalances deben controlarse para evitar sesgo en modelos.

# Correlaciones entre numericas:
#    - La mayoria de pares tienen correlacion cercana a 0.
#    - Balance vs NumOfProducts muestra correlacion negativa moderada (~–0.41).
#    - Buena independencia para modelos lineales.

# Conclusiones y siguientes pasos:
#  - Segmentar campañas de retencion hacia clientes mayores y mujeres, especialmente en Germany.
#  - Incluir interaccion Gender × Geography en el modelado.
#  - Avanzar a modelado predictivo (glm, arboles) con age, gender, geography como variables clave.
#  - Revisar si Balance y NumOfProducts aportan valor adicional en el modelo.


library(ggplot2)
library(scales)

ggplot(geoRate, aes(x = Geography, y = rate, fill = Exited)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.7) +
  # Añadir etiquetas con los porcentajes
  geom_text(aes(label = percent(rate, accuracy = 1)),
            position = position_dodge(width = 0.7),
            vjust = -0.3,
            size = 3) +
  scale_fill_manual(
    values = c("#003366", "#99CCFF"),   # azul oscuro y claro
    name   = "Exited",
    labels = c("No", "Sí")
  ) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    expand = expansion(mult = c(0, 0.1))
  ) +
  labs(
    x     = "Región",
    y     = "Tasa de abandono",
    title = "Abandono por Región"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x    = element_text(angle = 45, hjust = 1),
    legend.position = "top",
    plot.title     = element_text(face = "bold", hjust = 0.5)
  )
