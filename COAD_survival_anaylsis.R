# Colon Adenocarcinoma (TCGA-COAD) Clinical Survival Analysis
# Data source: TCGA GDC Data Portal
# Author: MSG-bio
# Date: June 2026

library(survival)
library(survminer)
library(ggplot2)
library(dplyr)
library(readr)

#load data

clinical <- read_tsv("clinical.tsv")

#Clean data

clinical_clean <- clinical %>%
  select(
    patient_id = `cases.submitter_id`,
    vital_status = `demographic.vital_status`,
    days_to_death = `demographic.days_to_death`,
    days_to_last_follow_up = `diagnoses.days_to_last_follow_up`,
    age = `demographic.age_at_index`,
    gender = `demographic.gender`,
    stage = `diagnoses.ajcc_pathologic_stage`
  ) %>%
  distinct() %>%
  filter(stage != "'--")


n_distinct(clinical_clean$patient_id)

clinical_clean %>%
  group_by(patient_id) %>%
  filter(n() > 1) %>%
  arrange(patient_id)

clinical_clean <- clinical_clean %>%
  group_by(patient_id) %>%
  slice(1) %>%
  ungroup()

# check that there is only one row per patient. Both lines should return the same number 
nrow(clinical_clean)

n_distinct(clinical_clean$patient_id)

#Stage mortality summary

stage_mortality <- clinical_clean %>%
  group_by(stage) %>%
  summarise(
    total_patients = n(),
    dead_patients = sum(vital_status == "Dead"),
    pct_dead = round((dead_patients / total_patients) * 100, 1)
  ) %>%
  arrange(desc(total_patients))

#Age by stage

stage_age <- clinical_clean %>%
  group_by(stage) %>%
  summarise(
    avg_age = round(mean(as.numeric(age), na.rm = TRUE),0)
  ) %>%
  arrange(desc(avg_age))

#Gender by stage

stage_gender <- clinical_clean %>%
  group_by(stage) %>%
  summarise(
    total_patients = n(),
    female_patients = sum(gender == "female"),
    male_patients = sum(gender == "male"),
    pct_female = round((female_patients / total_patients) * 100, 1),
    pct_male = round((male_patients / total_patients) * 100, 1)
  ) %>%
  arrange(desc(total_patients))

sum(stage_mortality$total_patients)
View (stage_mortality)


# Creating Kaplan-Meier variable (time, event)

clinical_clean <- clinical_clean %>%
  mutate(
    time = as.numeric(ifelse(vital_status == "Dead", 
                             days_to_death, 
                             days_to_last_follow_up)),
    event = ifelse(vital_status == "Dead", 1, 0)
  )

clinical_clean %>%
  select(patient_id, vital_status, days_to_death, days_to_last_follow_up, time, event)


sum(is.na(clinical_clean$time)) # see how many NAs there are and if it is worth filtering out

clinical_clean <- clinical_clean %>%
  filter(!is.na(time))

nrow(clinical_clean) #should be 446


#let's simplify the cancer stage groups into 4

clinical_clean <- clinical_clean %>%
  mutate(stage_group = case_when(
    stage %in% c("Stage I", "Stage IA") ~"Stage I",
    stage %in% c("Stage II", "Stage IIA", "Stage IIB", "Stage IIC") ~"Stage II",
    stage %in% c("Stage III", "Stage IIIA", "Stage IIIB", "Stage IIIC") ~"Stage III",
    stage %in% c("Stage IV", "Stage IVA","Stage IVB" ) ~"Stage IV",
  ))


table(clinical_clean$stage_group)

# Build the survival object

surv_object <- Surv( time = clinical_clean$time, event = clinical_clean$event)


# Use survfit() function to create survival curves across stage groups

km_fit <- survfit(surv_object ~ stage_group,
                  data = clinical_clean)


#Visuals 

png("KM_survival_by_stage.png", width = 10, height = 8, units = "in", res = 300)

ggsurvplot(km_fit,
           data = clinical_clean,
           pval = TRUE,
           conf.int = TRUE,
           risk.table = TRUE,
           risk.table.y.text = FALSE,
           legend.title = "Stage",
           legend.labs = c("Stage I", "Stage II", "Stage III", "Stage IV"),
           title = "Overall Survival by tumour Stage - TCGA COAD",
           xlab = "Days",
           ylab = "Survival Probability",
           palette =  c("#2E9FDF", "#00BA38", "#F8766D", "#C77CFF"))

dev.off()


#Cox proportional hazards model

clinical_clean <- clinical_clean %>%
  mutate(age = as.numeric(age))

cox_model <- coxph(Surv(time,event) ~ stage_group + age + gender,
                   data = clinical_clean)


summary(cox_model)

#Store Cox model results

cox_results <- data.frame(
  variable = rownames(summary(cox_model)$coefficients),
  hazard_ratio = round(summary(cox_model)$coefficients[,"exp(coef)"], 3),
  lower_95 = round(summary(cox_model)$conf.int[,"lower .95"], 3),
  upper_95 = round(summary(cox_model)$conf.int[,"upper .95"], 3),
  p_value = round(summary(cox_model)$coefficients[,"Pr(>|z|)"], 4)
)

write.csv(cox_results, "cox_results.csv", row.names = FALSE)
