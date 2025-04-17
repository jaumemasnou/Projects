
-- QUESTION 1: What is the number of tickets sold per month and year and their average price?

SELECT 
	YEAR(`Date of Purchase`) AS year,
    MONTH(`Date of Purchase`) AS month,
    COUNT(*) AS count_tickets,
    AVG(price) AS avg_price
FROM railway
GROUP BY YEAR(`Date of Purchase`), MONTH(`Date of Purchase`);     
  
  
-- QUESTION 2: What is the share of delayed trains per month and year? Which is the most important factor behind delays in trains?

SELECT
	YEAR(`Date of Purchase`) AS year,
    MONTH(`Date of Purchase`) AS month,	
    ROUND(SUM(CASE WHEN `Journey Status` = 'Delayed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS share_delayed_trains 
FROM railway
GROUP BY YEAR(`Date of Purchase`), MONTH(`Date of Purchase`);

SELECT
	`Reason for Delay`,
    ROUND(COUNT(`Reason for Delay`) / (SELECT COUNT(*) FROM railway WHERE `Journey Status` = 'Delayed') * 100, 2) AS share_reasons_delay
FROM railway
WHERE `Journey Status` = 'Delayed'
GROUP BY `Reason for Delay`
ORDER BY share_reasons_delay DESC;


-- QUESTION 3: What is the highest average price arrival destination for every departure station? 

WITH highest_price AS (
SELECT
	`Departure Station`,
    `Arrival Destination`,
    ROUND(AVG(`Price`), 2) AS avg_price,
    RANK() OVER(PARTITION BY `Departure Station` ORDER BY AVG(`Price`) DESC) AS ranked_price 
FROM railway
GROUP BY `Departure Station`, `Arrival Destination`
ORDER BY `Departure Station` ASC
)
SELECT
	`Departure Station`,
    `Arrival Destination`,
    avg_price
FROM highest_price
WHERE ranked_price = 1
ORDER BY avg_price DESC;
 
 
 -- QUESTION 4: What is average price of first class and standard ticket categories and its average price differential for different departure hours?
 
SELECT 
	HOUR(`Departure Time`) AS hour,
    `Ticket Class`,
    AVG(`Price`) AS average_price
FROM railway
GROUP BY HOUR(`Departure Time`), `Ticket Class`
ORDER BY hour;

SELECT 
  HOUR(`Departure Time`) AS hour,
  ROUND(
    AVG(CASE WHEN `Ticket Class` = 'First Class' THEN `Price` END) - 
    AVG(CASE WHEN `Ticket Class` = 'Standard' THEN `Price` END), 
    2
  ) AS price_difference
FROM railway
GROUP BY HOUR(`Departure Time`)
ORDER BY hour;

 -- QUESTION 5: What is the percentage of sales of each purchase type and departure station?
 
SELECT 
  `Purchase Type`,
  `Departure Station`,
  SUM(`Price`) AS sales,
  SUM(SUM(`Price`)) OVER(PARTITION BY `Departure Station`) AS station_sales,
  ROUND(SUM(`Price`) / SUM(SUM(`Price`)) OVER(PARTITION BY `Departure Station`) * 100, 2) AS percent_station_sales
FROM railway
GROUP BY `Purchase Type`, `Departure Station`
ORDER BY `Departure Station`;