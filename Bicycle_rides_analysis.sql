CREATE DATABASE IF NOT EXISTS Google_Rides;

USE Google_Rides;

CREATE TABLE rides (
	ride_id VARCHAR(100) PRIMARY KEY,
    rideable_type VARCHAR(100) NOT NULL,
    started_at DATETIME NOT NULL,
    ended_at DATETIME NOT NULL,
    start_station_name VARCHAR(200) NOT NULL,
    start_station_id INT NOT NULL,
    end_station_name VARCHAR(200) NOT NULL,
    end_station_id INT NOT NULL,
    user_type VARCHAR(100) NOT NULL,
    ride_length VARCHAR(100),
    days_of_week INT NOT NULL,
    monthly_use INT NOT NULL
);

DESCRIBE rides;

ALTER TABLE rides
MODIFY ride_length VARCHAR(100) NOT NULL;

SELECT * FROM rides;

CREATE TABLE IF NOT EXISTS rentals
SELECT * FROM rides;

SELECT * FROM rentals;

SELECT COUNT(*) FROM rentals;

-- converting ride_lenth from HH:MM:SS to Minutes

SELECT
	ROUND((SUBSTRING_INDEX(ride_length, ':', 1) * 60) +
    (SUBSTRING_INDEX(SUBSTRING_INDEX(ride_length, ':', 2), ':', -1)) + 
    (SUBSTRING_INDEX(ride_length, ':', -1)/60), 2) AS total_ride_length,
    ride_length
FROM rentals;

-- creating new column total_ride_length

ALTER TABLE rentals
ADD COLUMN total_ride_length DECIMAL(10,2);

-- Adding values to total_ride_length from ride_lenth

UPDATE rentals
SET total_ride_length = ROUND(
        (SUBSTRING_INDEX(ride_length, ':', 1) * 60) +
		(SUBSTRING_INDEX(SUBSTRING_INDEX(ride_length, ':', 2), ':', -1)) + 
		(SUBSTRING_INDEX(ride_length, ':', -1)/60), 
	2);

-- What is the average ride length for member’s vs casual riders?
SELECT
	ROUND(
		AVG(
			CASE
				WHEN user_type = 'member' THEN total_ride_length
			END), 
	2) AS Member,
	ROUND(
		AVG(
			CASE
				WHEN user_type = 'casual' THEN total_ride_length
			END),
	2) AS Casual
FROM rentals;
        
-- How many rides were taken by each user type per day of the week?
-- day_of_week or day name, rides taken by member, rides taken by user

SELECT 
	DAYNAME(started_at) as day_name,
    days_of_week,
    COUNT(
		CASE
			WHEN user_type = 'casual' THEN 1
		END
	 ) AS Casual_rides,
     COUNT(
		CASE
			WHEN user_type = 'member' THEN 1
		END
	 ) AS Member_rides
FROM rentals
GROUP BY day_name, days_of_week
ORDER BY days_of_week;

-- What is the distribution of rideable types per user type?
-- rideable_type | distribution(count) | member | casual

SELECT
	rideable_type,
    user_type,
     COUNT(rideable_type) AS distribution
FROM rides
GROUP BY rideable_type, user_type;

-- Do members ride more frequently in a month than casuals
-- month, member_frequency, casual_frequency

SELECT 
	MONTHNAME(started_at) AS month_name,
    SUM(
		CASE
			WHEN user_type = 'member' THEN monthly_use
		END
    ) AS member_frequency,
    SUM(
		CASE
			WHEN user_type = 'casual' THEN monthly_use
		END
    ) AS casual_frequency
    
 From rides
 GROUP BY month_name;
 
 --  What is the total and average ride duration? (considering user_type) 

SELECT
	user_type,
	SUM(total_ride_length) AS total,
    AVG(total_ride_length) AS average
FROM rentals
GROUP BY user_type;

-- What are the peakdays of the week for riding(overall and per usertype)?
-- day name or days_of_week | sum of rides | rides by members | rides by casual

SELECT 
	days_of_week,
    DAYNAME(started_at) AS day_name,
    COUNT(*) AS total_rides,
    COUNT(
		CASE
			WHEN user_type = 'member' THEN 1
		END
    ) AS rides_by_member,
    COUNT(
		CASE
			WHEN user_type = 'casual' THEN 1
		END
    ) AS rides_by_casual
FROM rentals
GROUP BY days_of_week, day_name
ORDER BY total_rides DESC;

-- What time of day do most rides start? (Hourly trend)
-- hour_of_day(1 to 24) | count(*)

SELECT 
    HOUR(started_at) AS hour_of_day,
	COUNT(*) AS total_rides
FROM rentals
GROUP BY hour_of_day
ORDER BY total_rides DESC;

-- Top 10 most popular start stations
-- station_name | total_rides

SELECT
	start_station_name AS station_name,
    COUNT(*) AS total_rides
FROM rentals
GROUP BY station_name
ORDER BY total_rides DESC
LIMIT 10;

--  Top 10 most popular endstations by casual vs member:
-- station_name | total_rides | members | casual

SELECT
	end_station_name AS station_name,
    COUNT(*) AS total_rides,
    COUNT(
		CASE
			WHEN user_type = 'member' THEN 1
		END
    ) AS rides_by_member,
    COUNT(
		CASE
			WHEN user_type = 'casual' THEN 1
		END
    ) AS rides_by_casual
FROM rentals
GROUP BY station_name
ORDER BY total_rides DESC
LIMIT 10;

-- Most common routes taken (start to end station):
-- start to end station name | count(*)

SELECT
 start_station_name,
 end_station_name,
 COUNT(*) AS total_rides
FROM rentals
GROUP BY start_station_name, end_station_name
ORDER BY total_rides DESC
LIMIT 10;

-- Which user type has longer average ride durations?
-- user_type | average ride duration (ride_length)

SELECT 
	user_type,
    ROUND(AVG(total_ride_length), 2) AS average_ride_duration
FROM rentals
GROUP BY user_type
ORDER BY average_ride_duration DESC
LIMIT 1;

-- Identify under used stations for potential closure or promotion:
-- start_station_name | rides_started | end_station_name | rides_ended

SELECT
	station_name,
    SUM(rides) AS ride_activity
FROM (
	SELECT
		start_station_name AS station_name,
		COUNT(*) AS rides
	FROM rentals
	GROUP BY start_station_name

	UNION ALL

	SELECT
		end_station_name AS station_name,
		COUNT(*) AS rides
	FROM rentals
	GROUP BY end_station_name
) AS total_rides
GROUP BY station_name
ORDER BY ride_activity
LIMIT 10;

-- Which stations have the most one-way drop-offs (not starting again)?
-- using CTE's compare station_name from start and end if a station has less start count than end the difference is the value
-- Station_name | total_rides_as_start | total_end_rides | difference

WITH start_activity AS (
	SELECT
		start_station_name AS station_name,
        COUNT(*) AS starting_rides
	FROM rentals
    GROUP BY station_name
), end_activity AS (
	SELECT
		end_station_name AS station_name,
        COUNT(*) AS ended_rides
	FROM rentals
    GROUP BY station_name
)

SELECT 
	s.station_name,
    s.starting_rides,
    e.ended_rides,
    e.ended_rides - s.starting_rides AS difference
FROM start_activity s
INNER JOIN end_activity e
ON s.station_name = e.station_name
GROUP BY station_name
ORDER BY difference DESC
LIMIT 10;

-- Which days have the highest average ride duration?
-- day_name | avg_ride_duration

SELECT
	DAYNAME(started_at) AS day_name,
    ROUND(AVG(total_ride_length), 2) AS avg_ride_duration
FROM rentals
GROUP BY day_name
ORDER BY avg_ride_duration DESC


-- THE END --


