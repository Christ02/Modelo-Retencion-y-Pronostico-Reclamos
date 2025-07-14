library(tidyverse)

claimsData = read_csv('test_claims.csv')

glimpse(claimsData)
summary(claimsData)

# verificar si tenemos nulos
missingSummary = claimsData %>%
  summarise(
    across(
      .cols = everything(),
      .fns  = ~ mean(is.na(.))
    )
  ) %>%
  pivot_longer(
    cols     = everything(),
    names_to = 'variable',
    values_to= 'propMissing'
  )

print(missingSummary)

# conteo de filas duplicadas
numDuplicates = sum(duplicated(claimsData))
print(numDuplicates)

# definimos las variables numericas
numericVars = c('age', 'bmi', 'children', 'charges')

# sacamos las stats
statsSummary = claimsData %>%
  summarise(
    across(
      .cols      = all_of(numericVars),
      .fns       = list(
        mean   = ~ mean(.),
        sd     = ~ sd(.),
        median = ~ median(.),
        min    = ~ min(.),
        max    = ~ max(.)
      ),
      .names     = '{.col}_{.fn}'
    )
  )

print(statsSummary)

# histograma de distribucion
claimsLong = claimsData %>%
  pivot_longer(
    cols      = all_of(numericVars),
    names_to  = 'variable',
    values_to = 'value'
  )

ggplot(claimsLong, aes(x = value)) +
  geom_histogram(bins = 30, fill = 'steelblue', alpha = 0.7) +
  facet_wrap(~ variable, scales = 'free') +
  labs(
    x     = NULL,
    y     = 'Count',
    title = 'Histogramas de Variables Numericas'
  ) +
  theme_minimal()

# Analisis de variables categoricas

claimsData = claimsData %>%
  rename(insuranceClaim = insuranceclaim)

# Definir variables categoricas
catVars = c('sex', 'smoker', 'region', 'insuranceClaim')

# Tabla de frecuencias y porcentajes
freqTable = claimsData %>%
  pivot_longer(
    cols      = all_of(catVars),
    names_to  = 'variable',
    values_to = 'value'
  ) %>%
  count(variable, value) %>%
  group_by(variable) %>%
  mutate(pct = n / sum(n)) %>%
  ungroup()

print(freqTable)

# Grafica de barras faceteada
ggplot(freqTable, aes(x = factor(value), y = n)) +
  geom_col(fill = 'salmon', alpha = 0.8) +
  geom_text(aes(label = scales::percent(pct, accuracy = 0.1)),
            vjust = -0.5, size = 3) +
  facet_wrap(~ variable, scales = 'free_x') +
  labs(
    x     = NULL,
    y     = 'Count',
    title = 'Frecuencias de Variables Categoricas'
  ) +
  theme_minimal()

#-----------------------------------------------------------
# Relacion entre variables y charges
#-----------------------------------------------------------


# Boxplots para variables categoricas vs charges
ggplot(claimsData, aes(x = factor(sex), y = charges)) +
  geom_boxplot(fill = 'lightblue', alpha = 0.7) +
  labs(
    x     = 'Sex (0=female,1=male)',
    y     = 'Charges (USD)',
    title = 'Charges por Sex'
  ) +
  theme_minimal()

ggplot(claimsData, aes(x = factor(smoker), y = charges)) +
  geom_boxplot(fill = 'lightgreen', alpha = 0.7) +
  labs(
    x     = 'Smoker (0=no,1=yes)',
    y     = 'Charges (USD)',
    title = 'Charges por Smoker'
  ) +
  theme_minimal()

ggplot(claimsData, aes(x = factor(region), y = charges)) +
  geom_boxplot(fill = 'lightcoral', alpha = 0.7) +
  labs(
    x     = 'Region (0=NE,1=NW,2=SE,3=SW)',
    y     = 'Charges (USD)',
    title = 'Charges por Region'
  ) +
  theme_minimal()

ggplot(claimsData, aes(x = factor(insuranceClaim), y = charges)) +
  geom_boxplot(fill = 'plum', alpha = 0.7) +
  labs(
    x     = 'Insurance Claim (0=no,1=yes)',
    y     = 'Charges (USD)',
    title = 'Charges por Insurance Claim'
  ) +
  theme_minimal()


# Scatterplots para variables numericas vs charges
numericVarsGraphs = c('age', 'bmi', 'children')

claimsLong2 = claimsData %>%
  pivot_longer(
    cols      = all_of(numericVarsGraphs),
    names_to  = 'variable',
    values_to = 'value'
  )

ggplot(claimsLong2, aes(x = value, y = charges)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = 'lm', se = FALSE) +
  facet_wrap(~ variable, scales = 'free_x') +
  labs(
    x     = NULL,
    y     = 'Charges (USD)',
    title = 'Scatterplots de Variables Numericas vs Charges'
  ) +
  theme_minimal()

library(corrplot)

corrMatrix = claimsData %>%
  select(all_of(numericVars)) %>%
  cor(use = 'pairwise.complete.obs')

corrplot(corrMatrix, method = 'shade', type = 'lower',
         tl.col = 'black', tl.cex = 0.8)
