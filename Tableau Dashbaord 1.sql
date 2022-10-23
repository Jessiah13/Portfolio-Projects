/*
Quries for Covid19 Tableau Dashboard.

*/

-- First Table: Shows total cases, deaths and the percentage of deaths. 
Select SUM (new_cases) As total_cases, SUM(Cast(new_deaths as int)) as total_deaths, SUM (Cast(new_deaths as int))/SUM (new_cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths$
Where continent is not null
Order by 1,2 

-- Second Table: Shows death count by country in descending order.
Select Location, Sum(cast(new_deaths as int)) as Total_Death_Count
From PortfolioProject..CovidDeaths$
Where continent is not null
and location not in ('World', 'European Union', 'International')
Group by location
Order by total_death_count desc

-- Third Table: shows population, infection count and infected poplation percentage. 
Select location, population, MAX(total_cases) as Highes_Infection_Count, Max((total_cases/population))*100 as Infected_Population_Percentage
From PortfolioProject..CovidDeaths$
Group by location, population
Order by Infected_Population_Percentage desc

-- Fourth Table: Shows locationm, population and infection count by date in descending order. 
Select location, population, date, MAX(total_cases) as Highest_Infection_Count, MAX((total_cases/population))*100 as Infected_Population_Percentage
From PortfolioProject..CovidDeaths$
Group by location, population, date
Order by Infected_Population_Percentage desc