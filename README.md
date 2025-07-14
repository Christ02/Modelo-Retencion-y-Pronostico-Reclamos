# Modelo-Retención-y-Pronóstico-Reclamos  
**Proyecto Final – Data Science for Finance**  
---

##  Descripción  
Este repositorio contiene dos pipelines de Machine Learning para **Europa Group**:  
1. **Churn (abandono)** – modelo de clasificación para predecir qué clientes de Europa Bank podrían abandonar.  
2. **Claims (reclamos)** – modelo de regresión para estimar los montos que Europa Insurance deberá pagar por sus reclamos médicos.

---

##  Estructura del repositorio  

```text
.
├── Data/                       # Carpeta con los datasets de entrada
│   ├── train_churn.csv         # Datos de entrenamiento para el modelo de churn
│   ├── test_churn.csv          # Datos de prueba para el modelo de churn
│   ├── train_claims.csv        # Datos de entrenamiento para el modelo de claims
│   └── test_claims.csv         # Datos de prueba para el modelo de claims
├── outputs/                    # Carpeta con los archivos de predicciones
│   ├── prediccionesChurn.csv   # Predicciones de abandono de clientes
│   └── prediccionesClaims.csv  # Predicciones de montos de reclamos
├── ModeloChurns.R              # Script de modelado y predicción de churn
├── PerfilamientoChurns.R       # Script de exploración y perfilamiento de churn
├── ModeloClaims.R              # Script de modelado y predicción de claims
├── PerfilamientoClaims.R       # Script de exploración y perfilamiento de claims
└── README.md                   # Documentación general del proyecto
```

---

## ⚙ Requisitos  
- **R** ≥ 4.0  
- Paquetes R:  
  - `tidyverse`  
  - `caret` o `tidymodels`  
  - `xgboost`  
  - `SHAPforxgboost`  
  - `corrplot`  
  - `ggplot2`  
  - `doParallel`  

Instalación rápida:
```r
install.packages(c(
  "tidyverse", "caret", "xgboost",
  "SHAPforxgboost", "corrplot", "ggplot2", "doParallel"
))
# ó, si usas tidymodels:
install.packages(c("tidyverse","tidymodels","xgboost","SHAPforxgboost","corrplot","ggplot2","doParallel"))
````

---

## 🚀 Uso

1. Clona el repositorio y coloca tu working directory en la carpeta raíz:

   ```r
   setwd("ruta/a/Modelo-Retención-y-Pronóstico-Reclamos")
   ```

2. **Parte 1 – Churn**

   * Explora y perfila los datos:

     ```r
     source("PerfilamientoChurns.R")
     ```
   * Entrena el modelo y genera `outputs/prediccionesChurn.csv`:

     ```r
     source("ModeloChurns.R")
     ```

3. **Parte 2 – Claims**

   * Explora y perfila los datos de reclamos:

     ```r
     source("PerfilamientoClaims.R")
     ```
   * Entrena el modelo y genera `outputs/prediccionesClaims.csv`:

     ```r
     source("ModeloClaims.R")
     ```

---

## 📈 Salidas

* **prediccionesChurn.csv**

  | CustomerId | Exited\_pred |
  | ---------- | ------------ |
  | ...        | 0 / 1        |

* **prediccionesClaims.csv**

  | id | charges |
  | -- | ------- |
  | …  | 1234.56 |

---

## 📄 Metodología

1. **EDA**

   * Boxplots y regresiones lineales para perfilamiento.
2. **Preprocesamiento**

   * Codificación one-hot, normalización y filtrado de variables de poca varianza.
3. **Modelado**

   * **Churn:** Random Forest y XGBoost, optimizados por F1-score (validación cruzada 5-fold).
   * **Claims:** XGBoost, optimizado por RMSE (tune\_grid / bayesiana).
4. **Evaluación**

   * Matriz de confusión, F1, RMSE, R², análisis de overfitting, importancia de variables y valores SHAP.

---

