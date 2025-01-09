-- CLEANING THE DATASET -- 

SELECT * 
FROM adult_income_raw;

-- UPDATE 'workclass', 'education' and 'occupation' into a smaller subset of groups, defining age groups, text trimming, renaming columns, 'null' values -- 
 
SELECT workclass
FROM adult_income_raw
GROUP BY workclass;

SET SQL_SAFE_UPDATES = 0;

UPDATE adult_income
SET workclass = 'Public'
WHERE TRIM(workclass) IN ('State-gov', 'Federal-gov', 'Local-gov');

UPDATE adult_income
SET workclass = 'Self-employed'
WHERE TRIM(workclass) IN ('Self-emp-not-inc', 'Self-emp-inc');

UPDATE adult_income
SET workclass = TRIM(workclass);

UPDATE adult_income
SET workclass = CASE 
                  WHEN workclass = '?' THEN NULL
                  ELSE workclass
                END;

ALTER TABLE adult_income_raw
CHANGE fnlwgt population INT;

SELECT education
FROM adult_income_raw
GROUP BY education;

UPDATE adult_income_raw
SET education = TRIM(education);

ALTER TABLE adult_income_raw
ADD COLUMN education_category TEXT;

UPDATE adult_income_raw
SET education_category = CASE
							WHEN education IN ('Preschool','1st-4th','5th-6th', '7th-8th','9th', '10th','11th') THEN 'Low'
                            WHEN education IN ('Some-college','Assoc-acdm', 'Assoc-voc','Prof-school', '12th','13th') THEN 'Intermediate'
                            WHEN education IN ('Bachelors','HS-grad','Masters', 'Doctorate') THEN 'High'
                            ELSE 'Unknown'
						END;

SELECT occupationintensity_emissionsintensity_emissions
FROM adult_income_raw
GROUP BY occupation;

UPDATE adult_income_raw
SET occupation = TRIM(occupation);

ALTER TABLE adult_income_raw
ADD COLUMN occupation_category TEXT;

UPDATE adult_income_raw
SET occupation_category = CASE
							WHEN occupation IN ('Farming-fishing','Protective-serv','Priv-house-serv','Handlers-cleaners') THEN 'Low'
                            WHEN occupation IN ('Adm-clerical','Other-service', 'Craft-repair','Sales', 'Transport-moving','Machine-op-inspct','Armed-Forces') THEN 'Intermediate'
                            WHEN occupation IN ('Exec-managerial','Prof-specialty','Tech-support') THEN 'High'
                            ELSE 'Unknown'
						END;

SELECT age
FROM adult_income_raw
GROUP BY age
ORDER BY age;

ALTER TABLE adult_income_raw
ADD COLUMN age_group TEXT;

UPDATE adult_income_raw
SET age_group = CASE
					WHEN age BETWEEN 17 AND 29 THEN 'Young'
					WHEN age BETWEEN 30 AND 45 THEN 'Adult'
					WHEN age BETWEEN 46 AND 65 THEN 'Seniors'
                    WHEN age > 65 THEN 'Old'
                    ELSE 'Unknown'
				END;


-- EXPLORATORY DATA ANALYSIS --

SELECT age_group, population, workclass, education_category, occupation_category, race, sex, salary
FROM adult_income_raw;


-- QUESTION 1. What's the share of workers (non-weighted average) whose salary is above 50.000$ per year (salary = 1)?

SELECT ROUND(SUM(salary)/COUNT(salary)*100,1) AS '% above 50.000$'
FROM adult_income_raw;


-- QUESTION 2. What's the share of workers (weighted average) whose salary is above 50.000$ per year (salary = 1)?

WITH population_salary AS
(
SELECT salary, population,
    CASE
        WHEN salary = 1 THEN population
        WHEN salary = 0 THEN 0
    END AS population_salary
FROM adult_income_raw
)    
SELECT ROUND(SUM(population_salary)/SUM(population)*100,1) AS '% above 50.000$'
FROM population_salary;


-- QUESTION 3. Males and females have a similar probability of earning a salary above 50.000$?

SELECT sex, ROUND(SUM(salary)/COUNT(salary)*100,1) AS '% above 50.000$'
FROM adult_income_raw
GROUP BY sex;


-- QUESTION 4. Wage disparities between males and females tend to be lower for younger cohorts?

SELECT sex, age_group, ROUND(SUM(salary)/COUNT(salary)*100,1) AS '% above 50.000$'
FROM adult_income_raw
GROUP BY sex, age_group
ORDER BY age_group DESC;


-- QUESTION 5. Wage disparities between males and females tend to be lower as education increases?

SELECT sex, education_category, ROUND(SUM(salary)/COUNT(salary)*100,1) AS '% above 50.000$'
FROM adult_income_raw
GROUP BY sex, education_category
ORDER BY education_category DESC;

SELECT 7.3/1.6 AS Gender_Wage_Gap_LowEduc, 31.0/9.2 AS Gender_Wage_Gap_IntEduc, 35.3/14.1 AS Gender_Wage_Gap_HighEduc;


-- QUESTION 6. Highly educated workers receive on average a wage premium compared to other groups?

SELECT education_category, ROUND(SUM(salary)/COUNT(salary)*100,1) AS '% above 50.000$'
FROM adult_income_raw
GROUP BY education_category
ORDER BY education_category DESC;


-- QUESTION 7. What is the share of highly educated workers within every single racial group?  

WITH population_sum AS
(
SELECT race, education_category, SUM(population) AS pop_sum
FROM adult_income_raw
GROUP BY race, education_category
ORDER BY race DESC
),
educated_pop AS
(
SELECT race, education_category, pop_sum,
SUM(pop_sum) OVER (PARTITION BY race) AS sum_pop_educ_race
FROM population_sum
ORDER BY race
)
SELECT race, education_category, pop_sum, sum_pop_educ_race, pop_sum/sum_pop_educ_race*100 AS share_race_educ
FROM educated_pop;
