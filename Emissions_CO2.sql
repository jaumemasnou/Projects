-- RENAMING COLUMNS -- 

ALTER TABLE capita_emissions
CHANGE COLUMN `Annual COâ‚‚ emissions (per capita)` Emissions_per_capita DECIMAL(4,2);

ALTER TABLE carbon_intensity_energy
CHANGE COLUMN `Annual COâ‚‚ emissions per unit energy (kg per kilowatt-hour)` Emissions_per_unit_energy DECIMAL(4,2);

ALTER TABLE carbon_intensity_gdp
CHANGE COLUMN `Annual COâ‚‚ emissions per GDP (kg per international-$)` Emissions_per_unit_GDP DECIMAL(4,2);

SELECT *
FROM carbon_intensity_gdp;


-- JOINING MULTIPLE TABLES --

SELECT 
ce.Entity AS Country, 
ce.year AS Year, 
ROUND(Emissions_per_capita,2) AS Emiss_pc, 
ROUND(Emissions_per_unit_energy,2) AS Emiss_pue, 
ROUND(Emissions_per_unit_GDP,2) AS Emiss_pugdp, 
Population, 
ROUND(Emissions_per_capita*Population,2) AS Total_Emissions
FROM capita_emissions ce
JOIN carbon_intensity_energy cie
	ON ce.Entity = cie.Entity
    AND ce.Year = cie.Year
JOIN carbon_intensity_gdp cigdp
	ON ce.Entity = cigdp.Entity
    AND ce.Year = cigdp.Year
JOIN population pop
	ON ce.Entity = pop.Entity
    AND ce.Year = pop.Year;


-- EXPLORATORY DATA ANALYSIS --

SELECT TRIM(Country) AS Country, TRIM(Year) AS Year, Emiss_pc, Emiss_pue, Emiss_pugdp, Population, Total_Emissions
FROM emissions_data;

SELECT *
FROM emissions_data;


-- QUESTION 1. Which country emitted more emissions in 2022?

SELECT Country, Year, Total_Emissions
FROM emissions_data
WHERE Year = 2022
ORDER BY Total_Emissions DESC;


-- QUESTION 2. Which country has emitted more emissions since 1965?

SELECT Country, SUM(Total_Emissions) AS Sum_total_emissions
FROM emissions_data
GROUP BY Country
ORDER BY Sum_total_emissions DESC;


-- QUESTION 3. What's the share of total emissions of Spain since 1965?

WITH share_emissions AS
(
SELECT Country, SUM(Total_Emissions) AS Sum_total_emissions
FROM emissions_data
GROUP BY Country
ORDER BY Sum_total_emissions DESC
),
share_emissions_country AS
(
SELECT 
Country, 
(Sum_total_emissions / SUM(Sum_total_emissions) OVER ()) * 100 AS Share_emissions
FROM share_emissions
ORDER BY Share_emissions DESC
)
SELECT Country, ROUND(Share_emissions,2)
FROM share_emissions_country
WHERE Country = 'Spain';


-- QUESTION 4. Which country has experienced the greatest decrease in per capita emissions between 2000 and 2022? 

WITH emissions_filtered AS 
(
SELECT 
Country,
Year,
Emiss_pc
FROM emissions_data
WHERE Year IN (2000, 2022) AND Country !='India'
),
emissions_pivot AS 
(
SELECT 
Country,
MAX(CASE WHEN Year = 2000 THEN Emiss_pc END) AS Emissions_pc_2000,
MAX(CASE WHEN Year = 2022 THEN Emiss_pc END) AS Emissions_pc_2022
FROM emissions_filtered
GROUP BY Country
)
SELECT 
Country,
((Emissions_pc_2022 - Emissions_pc_2000) / Emissions_pc_2000) * 100 AS Emissions_pc_Percentage_Change
FROM emissions_pivot
ORDER BY Emissions_pc_Percentage_Change ASC;


-- QUESTION 5. How much have emissions per capita declined since 2000 in aggregate terms (i.e. for all countries in the dataset)? 
-- Which factor (emissions per unit of enery or emissions per unit of GDP) has contributed the most to the fall in emissions per capita since 2000?

-- ANSWER : The decline of emissions per capita between 2000 and 2022 is largely explained by a decrease in the intensity of carbon emissions per unit of GDP. In other words, even though GDP per capita has increased over time, there has been an important decoupling between economic growth and CO2 emissions (explained by the fall of industrial activities as a share of GDP?).

WITH year_pop AS
(
SELECT Country, Year, Population, Emiss_pc, Emiss_pue, Emiss_pugdp,
SUM(Population) OVER (PARTITION BY Year) AS sum_pop 
FROM emissions_data
WHERE Country <> 'India' AND Country <> 'China'
),
weighted_pop AS
(
SELECT Country, Year, Emiss_pc, Emiss_pue, Emiss_pugdp, Population/sum_pop AS share_pop
FROM year_pop
),
weighted_emissions AS
(
SELECT Country, Year, Emiss_pc, Emiss_pue, Emiss_pugdp, share_pop, 
share_pop*Emiss_pc AS weighted_emiss_pc, 
share_pop*Emiss_pue AS weighted_emiss_pue, 
share_pop*Emiss_pugdp AS weighted_emiss_pugdp
FROM weighted_pop
)
SELECT Year, 
ROUND(SUM(weighted_emiss_pc),2) AS weigthed_emissions_pc, 
ROUND(SUM(weighted_emiss_pue),2) AS weighted_emiss_pue, 
ROUND(SUM(weighted_emiss_pugdp),2) AS weighted_emiss_pugdp 
FROM weighted_emissions
WHERE YEAR IN (2000, 2022)
GROUP BY Year;

