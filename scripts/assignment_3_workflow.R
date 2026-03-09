#installing and loading required packages
install.packages("ggrepel")
install.packages("corrplot")
library(glmnet)       
library(mlbench) 
library(pROC)         
library(ggplot2)
library(dplyr)
library(ggrepel) 
library(reshape2)
library(psych)

###TASK 1:

#loading and viewing dataset
data(PimaIndiansDiabetes2)
str(PimaIndiansDiabetes2)

#removing missing values 
nrow(PimaIndiansDiabetes2)
data_clean <- na.omit(PimaIndiansDiabetes2)
nrow(data_clean) 

#summary stats
describeBy(data_clean[, -which(names(data_clean) == "diabetes")],
           group = data_clean$diabetes)

#creating correlation matrix 
predictors <- data_clean[, -9]   
cor_matrix <- cor(predictors)
cor_matrix 

cor_long <- melt(cor_matrix)
heatmap_plot <- ggplot(cor_long, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                       midpoint = 0, limit = c(-1,1),
                       name = "Correlation") +
  theme_minimal() +
  labs(title = "Correlation Heatmap of Predictor Variables",
       x = "",
       y = "") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
heatmap_plot
ggsave("correlation_heatmap.png",
       plot = heatmap_plot,
       width = 8,
       height = 6,
       dpi = 300)

#splitting data into train and test
set.seed(123)
n <- nrow(data_clean)
train_index <- sample(1:n, size = 0.7 * n)
train_data <- data_clean[train_index, ]
test_data <- data_clean[-train_index, ]
nrow(train_data)
nrow(test_data)


###TASK 2: 

#fitting full logistic model
full_log <- glm(diabetes ~ pregnant + glucose + pressure + triceps +
                 insulin + mass + pedigree + age,
               data = train_data,
               family = binomial)
summary(full_log) 

#extracting model coefficients
coef_table <- summary(full_log)$coefficients
coef_table

#training predictions, ROC and AUC
train_probs <- predict(full_log, newdata = train_data, type = "response")
roc_train <- roc(train_data$diabetes, train_probs)
train_auc <- auc(roc_train)

#test predictions, ROC and AUC
test_probs <- predict(full_log, newdata = test_data, type = "response")
roc_test <- roc(test_data$diabetes, test_probs)
test_auc <- auc(roc_test)

train_auc
test_auc
roc.test(roc_train, roc_test)

###TASK 3: 

#creating squared terms for training data
train_expanded <- train_data %>%
  mutate(
    pregnant2 = pregnant^2,
    glucose2 = glucose^2,
    pressure2 = pressure^2,
    triceps2 = triceps^2,
    insulin2 = insulin^2,
    mass2 = mass^2,
    pedigree2 = pedigree^2,
    age2 = age^2
  )  

#creating two-way interaction terms for training data
X_interactions <- model.matrix(
  ~ (pregnant + glucose + pressure + triceps + insulin + mass + pedigree + age)^2,
  data = train_expanded
)[, -1] 

#combining to create expanded predictor space for training data
X_train <- cbind(
  X_interactions,
  train_expanded[, c("pregnant2","glucose2","pressure2","triceps2",
                     "insulin2","mass2","pedigree2","age2")] 
)
dim(X_train)

#creating squared terms for test data
test_expanded <- test_data %>%
  mutate(
    pregnant2 = pregnant^2,
    glucose2 = glucose^2,
    pressure2 = pressure^2,
    triceps2 = triceps^2,
    insulin2 = insulin^2,
    mass2 = mass^2,
    pedigree2 = pedigree^2,
    age2 = age^2
  )

#creating two-way interaction terms for test data
X_interactions_test <- model.matrix(
  ~ (pregnant + glucose + pressure + triceps + insulin + mass + pedigree + age)^2,
  data = test_expanded
)[, -1]

#combining to create expanded predictor space for test data
X_test <- cbind(
  X_interactions_test,
  test_expanded[, c("pregnant2","glucose2","pressure2","triceps2",
                    "insulin2","mass2","pedigree2","age2")]
)
dim(X_test)

#converting expanded matrices to data frames
X_train_df <- as.data.frame(X_train)
X_test_df  <- as.data.frame(X_test)

#ensuring training and test names are matching
colnames(X_train_df) <- make.names(colnames(X_train_df))
colnames(X_test_df)  <- make.names(colnames(X_test_df))

#adding the outcome variable to the expanded training df
train_expanded_df <- data.frame(diabetes = train_data$diabetes, X_train_df)

#fitting logistic regression on the expanded predictor space
expanded_log <- glm(diabetes ~ ., data = train_expanded_df, family = binomial)
summary(expanded_log)

#predicting probabilities on the training and test data
train_expanded_probs <- predict(expanded_log, type = "response")
test_expanded_probs <- predict(expanded_log, newdata = X_test_df, type = "response")

#creating ROC objects
roc_train_expanded <- roc(train_data$diabetes, train_expanded_probs)
roc_test_expanded <- roc(test_data$diabetes, test_expanded_probs)

#extracting AUC values
train_expanded_auc <- auc(roc_train_expanded)
test_expanded_auc <- auc(roc_test_expanded)

train_expanded_auc
test_expanded_auc 
roc.test(roc_train_expanded, roc_test_expanded)


###TASK 4: 

#preparing matrices for glmnet
X_train <- as.matrix(X_train)
X_test  <- as.matrix(X_test)

#preparing outcome
y_train <- ifelse(train_data$diabetes == "pos", 1, 0)
y_test  <- ifelse(test_data$diabetes == "pos", 1, 0)

#fitting lasso regression
cv_lasso <- cv.glmnet(
  x = X_train,
  y = y_train,
  family = "binomial",
  alpha = 1,
  nfolds = 10,
  type.measure = "deviance"
)

#creating cross-validation df
cv_data <- data.frame(
  lambda = cv_lasso$lambda,
  log_lambda = log(cv_lasso$lambda),
  cvm = cv_lasso$cvm,                 # mean CV error
  cvlo = cv_lasso$cvm - cv_lasso$cvsd, # lower error bar
  cvup = cv_lasso$cvm + cv_lasso$cvsd, # upper error bar
  nzero = cv_lasso$nzero              # number of non-zero coefficients
)

#extracting lambda values 
lambda_min <- cv_lasso$lambda.min
lambda_min
lambda_1se <- cv_lasso$lambda.1se
lambda_1se

#creating cv plot
cv_plot <- ggplot(cv_data, aes(x = log_lambda, y = cvm)) +
  geom_point(color = "#e76f51", size = 2) +
  geom_errorbar(aes(ymin = cvlo, ymax = cvup),
                width = 0.05, color = "darkgray") +
  geom_vline(xintercept = log(lambda_min),
             linetype = "dashed", color = "#2a9d8f", linewidth = 0.8) +
  geom_vline(xintercept = log(lambda_1se),
             linetype = "dashed", color = "#1e3a5f", linewidth = 0.8) +
  annotate("text", x = log(lambda_min), y = max(cv_data$cvup),
           label = "lambda.min", hjust = -0.1, color = "#2a9d8f", size = 3.5) +
  annotate("text", x = log(lambda_1se), y = max(cv_data$cvup) - 0.03,
           label = "lambda.1se", hjust = -0.1, color = "#1e3a5f", size = 3.5) +
  labs(
    x = expression(log(lambda)),
    y = "Binomial Deviance",
    title = "Lasso Cross-Validation Curve"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 11),
    panel.grid.minor = element_blank()
  )
cv_plot
ggsave("lasso_cv_curve.png", plot = cv_plot, width = 8, height = 6, dpi = 300)

#extracting coefficient matrix and lambda values
coef_matrix <- as.matrix(cv_lasso$glmnet.fit$beta)
lambda_values <- cv_lasso$glmnet.fit$lambda

#converting to data frame
coef_df <- as.data.frame(t(coef_matrix))
coef_df$lambda <- lambda_values
coef_df$log_lambda <- log(lambda_values)

#converting to long format
coef_long <- coef_df %>%
  pivot_longer(
    cols = -c(lambda, log_lambda),
    names_to = "variable",
    values_to = "coefficient"
  )

#getting lambda values
lambda_min <- cv_lasso$lambda.min
lambda_1se <- cv_lasso$lambda.1se

#identifying variables that are non-zero at lambda.1se
coef_1se <- as.matrix(coef(cv_lasso, s = "lambda.1se"))
coef_1se <- coef_1se[-1, , drop = FALSE]   # remove intercept
selected_vars <- rownames(coef_1se)[coef_1se[, 1] != 0]

#labelling selected variables at the left-most available point
label_data <- coef_long %>%
  filter(variable %in% selected_vars) %>%
  group_by(variable) %>%
  slice_min(order_by = log_lambda, n = 1) %>%
  ungroup()

#number of non-zero coefficients across lambdas
nzero_df <- data.frame(
  log_lambda = log(lambda_values),
  nzero = colSums(coef_matrix != 0)
)

#breaks for top axis
idx <- round(seq(1, length(lambda_values), length.out = 6))
top_breaks <- nzero_df$log_lambda[idx]
top_labels <- nzero_df$nzero[idx]

#plotting coefficient path plot
coef_path_plot <- ggplot(coef_long, aes(x = log_lambda, y = coefficient,
                                        group = variable, color = variable)) +
  geom_line(linewidth = 0.9, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = log(lambda_min),
             linetype = "dashed", color = "#00A087", linewidth = 0.9) +
  geom_vline(xintercept = log(lambda_1se),
             linetype = "dashed", color = "#E64B35", linewidth = 0.9) +
  geom_text_repel(
    data = label_data,
    aes(label = variable),
    direction = "y",
    hjust = 1,
    nudge_x = -0.4,
    segment.color = "grey60",
    segment.size = 0.3,
    size = 3.5,
    fontface = "bold",
    show.legend = FALSE
  ) +
  annotate("text", x = log(lambda_min), y = max(coef_long$coefficient, na.rm = TRUE) * 0.85,
           label = "lambda.min", color = "#00A087", hjust = -0.1, size = 4) +
  annotate("text", x = log(lambda_1se), y = max(coef_long$coefficient, na.rm = TRUE) * 0.72,
           label = "lambda.1se", color = "#E64B35", hjust = -0.1, size = 4) +
  scale_x_continuous(
    name = expression(log(lambda)),
    sec.axis = sec_axis(~ ., name = "Number of Non-Zero Coefficients",
                        breaks = top_breaks, labels = top_labels)
  ) +
  labs(
    title = "Lasso Coefficient Path",
    y = "Coefficients"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 11),
    panel.grid.minor = element_blank()
  )
coef_path_plot
ggsave("lasso_coefficient_path.png", plot = coef_path_plot,
       width = 8, height = 6, dpi = 300)

#extracting coefficients at lambda.min and lambda.1se
coef_min <- coef(cv_lasso, s = "lambda.min")
coef_1se <- coef(cv_lasso, s = "lambda.1se")

#extracting non-zero coefficients (excluding intercept)
nonzero_min <- coef_min[-1, 1][coef_min[-1, 1] != 0]
nonzero_1se <- coef_1se[-1, 1][coef_1se[-1, 1] != 0]

#listing the selected variables
nonzero_min
nonzero_1se

#counting number of selected predictors
num_min <- length(nonzero_min)
num_1se <- length(nonzero_1se)
num_min
num_1se


###TASK 5: 

#generating test AUC for simple logistic model
simple_test_probs <- predict(full_log, newdata = test_data, type = "response")
auc_simple <- auc(roc(test_data$diabetes, simple_test_probs, quiet = TRUE))

#generating test AUC for expanded logistic model
expanded_test_probs <- predict(expanded_log, newdata = X_test_df, type = "response")
auc_expanded <- auc(roc(test_data$diabetes, expanded_test_probs, quiet = TRUE))

#generating test AUC for lasso model at lambda.min
pred_lasso_min <- predict(cv_lasso, newx = X_test, s = "lambda.min", type = "response")
auc_lasso_min <- auc(roc(y_test, as.vector(pred_lasso_min), quiet = TRUE))

#generating test AUC for lasso model at lambda.1se
pred_lasso_1se <- predict(cv_lasso, newx = X_test, s = "lambda.1se", type = "response")
auc_lasso_1se <- auc(roc(y_test, as.vector(pred_lasso_1se), quiet = TRUE))

#summary table comparing all four models
comparison <- data.frame(
  Model = c("Simple", "Full", "Lasso min", "Lasso 1se"),
  Predictors = c(8, 44, num_min, num_1se),
  Test_AUC = round(c(auc_simple, auc_expanded, auc_lasso_min, auc_lasso_1se), 4)
)
comparison

#creating ROC curves for all models
roc_simple <- roc(test_data$diabetes, simple_test_probs, quiet = TRUE)
roc_full <- roc(test_data$diabetes, expanded_test_probs, quiet = TRUE)
roc_lasso_min <- roc(y_test, as.vector(pred_lasso_min), quiet = TRUE)
roc_lasso_1se <- roc(y_test, as.vector(pred_lasso_1se), quiet = TRUE)

#converting ROC object to data frame
roc_to_df <- function(roc_obj, model_name) {
  data.frame(
    sensitivity = roc_obj$sensitivities,
    specificity = roc_obj$specificities,
    model = model_name
  )
}

#combinfing ROC data for plotting
roc_data <- bind_rows(
  roc_to_df(roc_simple, paste0("Simple (8 vars): AUC = ", round(auc(roc_simple), 3))),
  roc_to_df(roc_full, paste0("Full (44 vars): AUC = ", round(auc(roc_full), 3))),
  roc_to_df(roc_lasso_min, paste0("Lasso min (", num_min, " vars): AUC = ", round(auc(roc_lasso_min), 3))),
  roc_to_df(roc_lasso_1se, paste0("Lasso 1se (", num_1se, " vars): AUC = ", round(auc(roc_lasso_1se), 3)))
)

#setting factor levels to control legend order
roc_data$model <- factor(
  roc_data$model,
  levels = unique(roc_data$model)
)

#plotting ROC curves
roc_plot <- ggplot(roc_data, aes(x = 1 - specificity, y = sensitivity, color = model)) +
  geom_line(linewidth = 1.2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
  labs(
    x = "1 - Specificity (False Positive Rate)",
    y = "Sensitivity (True Positive Rate)",
    title = "ROC Curves: Model Comparison",
    color = ""
  ) +
  coord_equal() +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    legend.direction = "vertical"
  )
roc_plot
ggsave("model_comparison_roc.png", plot = roc_plot, width = 8, height = 6, dpi = 300)


###TASK 6: 

#extracting non-zero coefficients at lambda.1se (excluding intercept)
coef_1se <- coef(cv_lasso, s = "lambda.1se")
nonzero_1se <- coef_1se[-1, 1][coef_1se[-1, 1] != 0]

#creating data frame for plotting
coef_1se_df <- data.frame(
  Variable = names(nonzero_1se),
  Coefficient = as.numeric(nonzero_1se)
)

#ordering variables by coefficient size
coef_1se_df$Variable <- factor(
  coef_1se_df$Variable,
  levels = coef_1se_df$Variable[order(coef_1se_df$Coefficient)]
)

#creating bar chart of non-zero coefficients
coef_bar_plot <- ggplot(coef_1se_df, aes(x = Variable, y = Coefficient)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Non-Zero Coefficients at lambda.1se",
    x = "Variable",
    y = "Coefficient"
  ) +
  theme_minimal()
coef_bar_plot
ggsave("lasso_lambda_1se_coefficients.png", plot = coef_bar_plot,
       width = 8, height = 6, dpi = 300)