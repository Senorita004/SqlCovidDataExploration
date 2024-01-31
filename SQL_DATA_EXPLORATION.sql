/*
Covid 19 Data Exploration With SQL Queries

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject.dbo.CovidDeaths
order by 3,4

-- Selecting data to be used
Select Location, date, total_cases, new_cases, total_deaths, population 
From PortfolioProject.dbo.CovidDeaths
order by 1, 2

-- Looking at total cases vs total deaths
Select Location, date, total_cases, total_deaths, (CAST(total_deaths as float)/total_cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
order by 1, 2

-- Looking at total cases vs population; percentage of population has covid
Select Location, date, Population, total_cases, (CAST(total_cases as float)/Population)*100 as InfectedPopulationPercent
From PortfolioProject.dbo.CovidDeaths
WHERE Location LIKE '%Nigeria%'
order by 1, 2

-- Looking at Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX(CAST(total_cases as float)/Population)*100 as MaxInfectedPopulationPercent
FROM PortfolioProject.dbo.CovidDeaths
Group By Location, Population
order by MaxInfectedPopulationPercent desc

-- Showing Continents with the highest death count per population
Select continent, MAX(total_deaths) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
order by HighestDeathCount desc

-- Looking at total cases vs total deaths
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (CAST(SUM(new_deaths) as float)/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 1, 2

Select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (CAST(SUM(new_deaths) as float)/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
where continent is not null
Group by date
order by 1, 2


--Looking at Total population vs vaccinations 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
From PortfolioProject..CovidVaccinations as vac
JOIN PortfolioProject..CovidDeaths as dea
    ON vac.location= dea.location
    and vac.date = dea.date
where dea.continent is not null 
order by 2,3

-- Finding the daily percentage of people vaccinated by population, we cant use a column named(RollingVaccinationCount) to make calculations.
-- Method 1 (Using CTE)- cte columns should equal those in your select statement
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidVaccinations as vac
JOIN PortfolioProject..CovidDeaths as dea
    ON vac.location= dea.location
    and vac.date = dea.date
where dea.continent is not null 
-- order by 2,3---- cte does not accept order by
)

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinatedPercent
From PopvsVac

--Method 2 (Using a temp table) 
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
   Continent nvarchar(255),
   Location NVARCHAR(255),
   Date datetime,
   Population numeric,
   New_vaccinations numeric,
   RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidVaccinations as vac
JOIN PortfolioProject..CovidDeaths as dea
    ON vac.location= dea.location
    and vac.date = dea.date
where dea.continent is not null 

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPeopleVaccinatedPercent
From #PercentPopulationVaccinated


--Creating View to store data for later visualisations.
DROP View if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidVaccinations as vac
JOIN PortfolioProject..CovidDeaths as dea
    ON vac.location= dea.location
    and vac.date = dea.date
where dea.continent is not null 
-- order by 2,3---- does not work in views

Select *
From PercentPopulationVaccinated
