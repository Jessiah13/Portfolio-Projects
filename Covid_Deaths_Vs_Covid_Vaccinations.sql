
SELECT *
FROM PortfolioProject..CovidDeaths$
--WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations$
WHERE continent is not null
ORDER BY 3,4

-- Selecting the data that will be using. 
SELECT 
	location, date, total_cases, new_cases, total_deaths, Population
FROM 
	PortfolioProject..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2


-- Looking at total cases vs total deaths
-- Shows the likelihood of dying if you contract Covid in your country.
SELECT 
	location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as Death_Percentage
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	location = 'Trinidad and Tobago' AND continent is not null
ORDER BY 1,2


-- Looking at the total_cases vs population
-- Shows what percentage of the population contracted covid. 
SELECT 
	location, date, population, total_cases, (total_cases/population)*100 as Infection_Percentage
FROM 
	PortfolioProject..CovidDeaths$
WHERE
	location = 'Trinidad and Tobago' AND continent is not null
ORDER BY 1,2


-- Looking at Countries with the Highest Infection Rate compared to Population
SELECT 
	location, population, MAX (total_cases) as Highest_Infection_Count, MAX ((total_cases/population))*100 as Infection_Percentage
FROM 
	PortfolioProject..CovidDeaths$
WHERE continent is not null -- AND location = 'Trinidad and Tobago'
GROUP BY Location, Population
ORDER BY Infection_Percentage desc


--Looking at the countries with the highest death count. 
SELECT
	location, MAX(cast(total_deaths as int)) as Total_Death_Count
FROM 
	PortfolioProject..CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY Total_Death_Count desc


-- BREAKING DOWN BY CONTINENT
--showing continents with the highest death count
SELECT
	location, MAX(cast(total_deaths as int)) as Total_Death_Count
FROM 
	PortfolioProject..CovidDeaths$
WHERE continent is null
GROUP BY location
ORDER BY Total_Death_Count desc


-- GLOBAL NUMBERS

SELECT
	location, SUM (total_Cases) as total_cases, SUM(cast(total_deaths as int))  as Total_Death_Count,
	SUM(cast(total_deaths as int))/SUM (total_Cases) *100 as Death_Percentage 
FROM 
	PortfolioProject..CovidDeaths$
WHERE location = 'World' AND continent is null
GROUP BY location
ORDER BY Total_Death_Count desc


--Joining Covid deaths and Covid Vaccination tables
SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations,
	SUM (CONVERT ( int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths$ as dea
JOIN PortfolioProject..CovidVaccinations$ as vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Creating Temp table.

Drop Table if Exists #VaccinatedPopulationPercentage
Create Table #VaccinatedPopulationPercentage
(
continent nvarchar(255),
location nvarchar (255),
date datetime,
population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #VaccinatedPopulationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM (CONVERT ( int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths$ as dea
JOIN PortfolioProject..CovidVaccinations$ as vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (Rolling_People_Vaccinated/Population)*100
FROM #VaccinatedPopulationPercentage