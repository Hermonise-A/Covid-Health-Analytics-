---- COVID Death and Vaccination Data Analytics Project 

--- To ensure Covid Vaccination table was properly imported 

SELECT *
FROM covid_vax
ORDER BY location

--- To ensure Covid Deaths table was properly imported 

SELECT *
FROM covid_deaths
ORDER BY location

--- Review key insights on Covid Deaths table 

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM covid_deaths
ORDER BY location

--- Taking a look at Total Cases Vs. Total Deaths : Chance of passing if Covid is contracted 

SELECT location, date, total_cases, total_deaths,ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM covid_deaths
ORDER BY location

--- Received error as total_deaths and total_cases are presented as nvarchar instead of float. Nvarchar data types can not utilize divide operator

ALTER TABLE covid_deaths
ALTER COLUMN total_deaths float

ALTER TABLE covid_deaths
ALTER COLUMN total_cases float

ALTER TABLE covid_deaths
ALTER COLUMN new_cases float

ALTER TABLE covid_deaths
ALTER COLUMN new_deaths float

--- Now query can run proper calculation 

SELECT location, date, total_cases, total_deaths,ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM covid_deaths
ORDER BY location

--- Reviewing Total Cases Vs. Population : Percent of population that contracted Covid 

SELECT location, date, total_cases, population,(total_cases/population)*100 AS covid_percentage
FROM covid_deaths
ORDER BY location

--- Reviewing Countries with Highest Infection Rate compared to Population 

SELECT location, population, MAX(total_cases) AS Highest_InfectionCount, ROUND(MAX((total_cases/population)*100), 2) AS PopulationInfected_Percent
FROM covid_deaths
GROUP BY location, population
ORDER BY PopulationInfected_Percent DESC


--- Reviewing Contintent with Highest Infection Rate compared to Population 

SELECT continent, MAX(total_cases) AS Highest_InfectionCount, ROUND(MAX((total_cases/population)*100), 2) AS PopulationInfected_Percent
FROM covid_deaths
GROUP BY continent
ORDER BY PopulationInfected_Percent DESC

--- After review we are seeing NULL values for continent
--- New query to look into cause of NULL value 

SELECT location, continent
FROM covid_deaths
WHERE continent IS NULL 
GROUP BY location, continent 


--- Null values belong to groups of countries where the continent is either the location or the continent is in reference to a larger group of locations ie. socio-econonomic group. 
--- These can be removed from our query but we notice the count is skewed such that not every country is added into the continent. We can filter out extra data  
--- New query provided 

SELECT location, MAX(total_cases) AS Highest_InfectionCount, ROUND(MAX((total_cases/population)*100), 2) AS PopulationInfected_Percent
FROM covid_deaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%' 
	AND location NOT LIKE '%world%'
	AND location NOT LIKE '%union%'
GROUP BY location
ORDER BY PopulationInfected_Percent DESC

--- Reviewing Countries with Highest Death Count compared to Population 

SELECT location, MAX(total_deaths) AS Total_DeathCount, ROUND(MAX((total_deaths/population)*100), 2) AS PopulationDeath_Percent
FROM covid_deaths
GROUP BY location
ORDER BY PopulationDeath_Percent DESC

--- Reviewing Contintent with Highest Death Count compared to Population 

SELECT location, MAX(total_deaths) AS Total_DeathCount, ROUND(MAX((total_deaths/population)*100), 2) AS PopulationDeath_Percent
FROM covid_deaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%' 
	AND location NOT LIKE '%world%'
	AND location NOT LIKE '%union%'
GROUP BY location
ORDER BY PopulationDeath_Percent DESC

--- Note while Europe has the highest infection count South America has the highest death percentage 

--- Global Death Percentage 

SELECT SUM(new_cases) AS total_cases,SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases) *100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--- Covid Deaths in Relation to Covid Vaccinations 
--- Review of vaccination data

SELECT *
FROM covid_vax
ORDER BY location

--- Joining of tables such that location and date on death table is equal to location and date on vaccination table 

SELECT * 
FROM covid_deaths AS dea
JOIN covid_vax AS vax 
	ON dea.location = vax.location 
	AND dea.date = vax.date 

--- Reviewing the total amount of people vaccinated within a country as new vaccinations are provided by daily  

SELECT dea.location, dea.continent, dea.date, dea.population, vax.new_vaccinations, SUM(CAST(vax.new_vaccinations AS FLOAT)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_VaxCount 
FROM covid_deaths AS dea
JOIN covid_vax AS vax 
	ON dea.location = vax.location 
	AND dea.date = vax.date 
WHERE dea.continent IS NOT NULL 
ORDER BY dea.location, dea.date;


--- Using CTE to review total vaccination by population 

WITH Vax_Population (location, continent, date, population, new_vaccinations, Rolling_VaxCount)
AS 
(SELECT dea.location, dea.continent, dea.date, dea.population, vax.new_vaccinations, SUM(CAST(vax.new_vaccinations AS FLOAT)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_VaxCount 
FROM covid_deaths AS dea
JOIN covid_vax AS vax 
	ON dea.location = vax.location 
	AND dea.date = vax.date 
WHERE dea.continent IS NOT NULL)
SELECT *, (Rolling_VaxCount/population)*100 AS Total_VaxPercent
FROM Vax_Population


--- Creating Temp Table to use moving foward

DROP TABLE IF EXISTS Percent_PopulationVax
CREATE TABLE Percent_PopulationVax 
(
	continent nvarchar(255),
	location nvarchar(255),
	date date,
	population float,
	new_vaccinations float,
	Rolling_VaxCount float
	)

INSERT INTO Percent_PopulationVax
SELECT dea.location, dea.continent, dea.date, dea.population, vax.new_vaccinations, SUM(CAST(vax.new_vaccinations AS FLOAT)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_VaxCount 
FROM covid_deaths AS dea
JOIN covid_vax AS vax 
	ON dea.location = vax.location 
	AND dea.date = vax.date 
WHERE dea.continent IS NOT NULL 

--- To ensure table was properly created

SELECT *
FROM Percent_PopulationVax
