
-- 1)CREATE DATABASE and CLEAN DATA
CREATE DATABASE COAD_clinical;
USE COAD_clinical;

DESCRIBE clinical;

SELECT 
    `cases.submitter_id`,
    `demographic.vital_status`,
    `demographic.days_to_death`,
    `diagnoses.days_to_last_follow_up`,
    `demographic.age_at_index`,
    `demographic.gender`,
    `diagnoses.ajcc_pathologic_stage`
FROM clinical
LIMIT 10;

-- We need to remove duplicates and filter out rows where the Stage is missing

SELECT distinct
    `cases.submitter_id`,
    `demographic.vital_status`,
    `demographic.days_to_death`,
    `diagnoses.days_to_last_follow_up`,
    `demographic.age_at_index`,
    `demographic.gender`,
    `diagnoses.ajcc_pathologic_stage`
FROM clinical
WHERE `diagnoses.ajcc_pathologic_stage` != '--' 
LIMIT 10;

SELECT distinct `diagnoses.ajcc_pathologic_stage`
FROM clinical;

SELECT DISTINCT
    `cases.submitter_id`,
    `demographic.vital_status`,
    `demographic.days_to_death`,
    `diagnoses.days_to_last_follow_up`,
    `demographic.age_at_index`,
    `demographic.gender`,
    `diagnoses.ajcc_pathologic_stage`
FROM clinical
WHERE `diagnoses.ajcc_pathologic_stage` != "'--"
;

CREATE TABLE clinical_clean AS
SELECT DISTINCT    
 `cases.submitter_id` AS patient_id,
    `demographic.vital_status` AS vital_status,
    `demographic.days_to_death` AS days_to_death,
    `diagnoses.days_to_last_follow_up` AS days_to_last_follow_up,
    `demographic.age_at_index` AS age,
    `demographic.gender` AS gender,
    `diagnoses.ajcc_pathologic_stage` AS stage
FROM clinical
WHERE `diagnoses.ajcc_pathologic_stage` != "'--"
;

SELECT *
FROM clinical_clean
LIMIT 10;

-- 2) How many Patients are in each cancer stage, and how many have died?

SELECT stage, COUNT(patient_id) AS total_patients,
    SUM(CASE WHEN vital_status = 'Dead' THEN 1 ELSE 0 END) AS dead_patients
FROM clinical_clean
GROUP by stage
ORDER BY total_patients DESC
LIMIT 20;

with stage_summary AS
(SELECT stage, COUNT(patient_id) AS total_patients,
    SUM(CASE WHEN vital_status = 'Dead' THEN 1 ELSE 0 END) AS dead_patients
FROM clinical_clean
GROUP by stage
)
SELECT stage, total_patients, dead_patients,
ROUND((dead_patients / total_patients) * 100, 1) AS pct_dead
FROM stage_summary
ORDER BY total_patients DESC;

-- Average age per stage

select *
FROM clinical_clean
LIMIT 10;

SELECT stage, ROUND(AVG(age), 0) AS avg_age_per_stage
FROM clinical_clean
group by stage
ORDER BY 2 DESC;

-- Gender grouping by stage


SELECT stage, count(gender) AS total_patients, 
SUM(CASE WHEN gender = 'female' then 1 else 0 END) AS female_patients,
SUM(CASE WHEN gender = 'male' then 1 else 0 END) AS male_patients
FROM clinical_clean
group by stage
ORDER BY 2 DESC;

With gender_stats AS
(SELECT stage, count(gender) AS total_patients, 
SUM(CASE WHEN gender = 'female' then 1 else 0 END) AS female_patients,
SUM(CASE WHEN gender = 'male' then 1 else 0 END) AS male_patients
FROM clinical_clean
group by stage
)
SELECT stage, total_patients, female_patients, male_patients,
ROUND((female_patients / total_patients) * 100, 1) AS pct_female,
ROUND((male_patients / total_patients) * 100, 1) AS pct_male
FROM gender_stats
ORDER BY 2 DESC; 







