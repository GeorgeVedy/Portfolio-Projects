
-- Making sure both tables are working and look correct:

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
;

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
;



-- Select the data I would like to use:

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2
;



-- Total Cases vs Total Deaths - showing the likelihood of dying if you contract Covid in your country:

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%kingdom%'
ORDER BY 1,2
;



-- Total Cases vs Population - showing the percentage of the population who have contracted Covid:

SELECT location, date, population, total_cases, (total_cases/population)*100 AS percentage_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United Kingdom'
ORDER BY 1,2
;



-- Countries with highest infection rate compared to population:

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percentage_population_infected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY percentage_population_infected DESC
;



-- Countries with highest death count compared to population:

-- Was an issue reading total_deaths as a data type so I am casting it as an integer wherever needed
-- Noticed that the data for continents was also being grouped and stated as a country so filtered this out

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC
;



-- Continents with highest death count compared to population (two ways):

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC
;

SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC
;



-- Global figures - per day:

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2
;



-- Global figures - in total:

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2
;



-- Joining CovidDeaths and CovidVaccinations tables on location and date as this should be suitably specific:

SELECT *
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
;



-- Total population vs vaccinations:

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
;



-- Adding rolling count of new_vaccinations:

-- Partitioning by location as we want the count to restart with every country
-- Using an alternative way of formatting as an integer

SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
;



-- Using CTE to find the percentage of a country population that are vaccinated at a given date:

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100 AS percentage_population_vaccinated
FROM PopvsVac
;



-- Using a temp table to find the percentage of a country population that are vaccinated at a given date:

-- Have to specifiy data type

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT *, (rolling_people_vaccinated/population)*100 AS percentage_population_vaccinated
FROM #percent_population_vaccinated
;



-- Creating View for visualisations:

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
;

SELECT *
FROM percent_population_vaccinated
;