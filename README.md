# Lasso-Regression-and-Logistic-Modelling-for-Diabetes-Risk-Prediction

This repository contains a statistical analysis of the Pima Indians Diabetes dataset using logistic regression and Lasso regularisation in R. The project was completed as part of the Advanced Data Analytics module in the MSc Technologies and Analytics in Precision Medicine.

The analysis investigates which clinical variables best predict diabetes and evaluates how model complexity and regularisation influence predictive performance.

## Project Overview

Type 2 diabetes is a major global health concern, and early identification of individuals at risk is critical for prevention and treatment. The Pima Indian population of Arizona has one of the highest documented prevalence rates of diabetes worldwide, making this cohort particularly useful for studying disease predictors.

This analysis uses the Pima Indians Diabetes 2 dataset, which contains clinical measurements from 768 women aged 21 years or older.

The objectives of the study were to:

- Identify clinical predictors of diabetes
 Evaluate logistic regression models of varying complexity
- Apply Lasso regression to perform variable selection
- Compare predictive performance using ROC curves and AUC values
- Logistic regression was used as the primary modelling approach because the outcome variable (diabetes status) is binary. 

Research Question:

Which clinical and demographic factors best predict diabetes risk, and how does regularisation influence model performance when the predictor space becomes large? #

---
## Dataset

The Pima Indians Diabetes 2 dataset includes diagnostic measurements from women aged 21 years or older.

- pregnant:	Number of pregnancies
- glucose:	Plasma glucose concentration
- pressure:	Diastolic blood pressure
- triceps:	Triceps skinfold thickness
- insulin:	Serum insulin
- mass:	Body mass index (BMI)
- pedigree:	Diabetes pedigree function
- age:	Age of participant
- diabetes:	Diabetes status (positive/negative)

After removing missing values, the cleaned dataset contained 392 observations used for model training and evaluation. 

---
## Methods

The analysis was conducted in R using the following packages:

- glmnet
- mlbench
- pROC
- ggplot2
- dplyr
- corrplot
- ggrepel

The workflow consisted of six main stages.

### 1. Data Preparation and Exploration

Data preprocessing steps included:

- Removing observations containing missing values
- Generating summary statistics for each variable
- Examining correlations between predictors using a correlation matrix heatmap

The heatmap revealed mostly weak-to-moderate correlations, indicating limited multicollinearity between predictors.

The strongest correlation was observed between triceps skinfold thickness and BMI, both measures of body adiposity. 

### 2. Logistic Regression Model

A baseline logistic regression model was fitted using the eight original predictors.

Model performance was evaluated using the Area Under the Receiver Operating Characteristic Curve (AUC).

- Training set:	0.8768
- Test set:	0.8034

The modest difference between training and test AUC suggests limited overfitting, indicating that the model generalises reasonably well to unseen data. 

### 3. Expanded Predictor Model

To explore more complex relationships, an expanded predictor space was created including:

- Squared polynomial terms
- All two-way interaction terms between predictors

This resulted in a model containing 44 predictors.

While this model achieved a higher training AUC (0.93), the test AUC dropped to 0.73, indicating substantial overfitting due to increased model complexity. 

### 4. Lasso Regression

To address overfitting, Lasso regression was applied using 10-fold cross-validation.

The optimal regularisation parameters were identified:

- λmin – model with minimum cross-validation error
- λ1se – more parsimonious model within one standard error

Lasso regression shrinks coefficient estimates and sets many coefficients to zero, effectively performing automatic variable selection.

Selected Variables:

The parsimonious model at λ1se retained four predictors:

- glucose
- glucose²
- glucose × mass
- glucose × age

These predictors indicate that:

- plasma glucose is the dominant predictor of diabetes risk
- the relationship between glucose and diabetes may be non-linear
- glucose risk effects may vary depending on BMI and age. 

### 5. Model Comparison

Four models were compared using test AUC values.

| Model | Predictors | Test AUC |
|:------|-----------:|---------:|
| Simple | 8 | 0.803 |
| Expanded | 44 | 0.731 |
| Lasso (λmin) | 11 | 0.812 |
| Lasso (λ1se) | 4 | 0.784 |

The Lasso model at λmin achieved the highest predictive performance, demonstrating the benefit of regularisation when dealing with large predictor spaces. 

## Key Results

The analysis demonstrated that:

- Plasma glucose is the strongest predictor of diabetes risk
- Increasing model complexity can lead to overfitting
- Regularised models such as Lasso improve predictive performance
- Interactions between glucose, BMI, and age influence diabetes risk
- These findings align with known biological mechanisms linking hyperglycaemia, adiposity, and insulin resistance to type 2 diabetes development. 

##Running the Analysis

Clone the repository:
git clone https://github.com/aminat13/<repository-name>

Open the R workflow script:
scripts/assignment_3_workflow.R

Running the script will reproduce:

- data preprocessing
- logistic regression models
- Lasso regression analysis
- ROC curve comparisons
- visualisation of selected variables

## Skills Demonstrated

This project demonstrates practical skills in:

Logistic regression modelling

- Feature engineering and interaction modelling
- Regularisation using Lasso regression
- Cross-validation
- ROC curve analysis and AUC interpretation
- Model comparison and overfitting assessment
- Reproducible statistical analysis in R

## References

Cao, C. et al. (2024).
Nonlinear relationship between triglyceride-glucose index and the risk of prediabetes and diabetes.
Frontiers in Endocrinology. 

Chia, C. W., Egan, J. M., & Ferrucci, L. (2018).
Age-related changes in glucose metabolism, hyperglycemia, and cardiovascular risk.
Circulation Research. 

Goyal, S. et al. (2023).
Genetics of diabetes.
World Journal of Diabetes. 

Haines, M. S. et al. (2022).
Association between muscle mass and diabetes prevalence independent of body fat distribution.
Nutrition & Diabetes. 

Mukkamala, N. et al. (2021).
Relationship between Body Mass Index and Skin Fold Thickness in Young Females.
Journal of Pharmaceutical Research International. 

Wilcox, G. (2005).
Insulin and insulin resistance.
Clinical Biochemist Reviews. 

Zhao, X. et al. (2024).
The combination of body mass index and fasting plasma glucose is associated with type 2 diabetes mellitus.
Frontiers in Endocrinology. 

---
The dataset was loaded in R using the `PimaIndiansDiabetes2` dataset available in the `mlbench` package.
