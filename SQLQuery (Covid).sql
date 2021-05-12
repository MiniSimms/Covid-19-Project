/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, and Data validation
*/

-- Selecting the data that I am going start with
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjectCovid..CovidDeaths
Where continent is not null 
order by 1,2



--What days did the United States have more new vaccines shots than new cases and vice versa
Select dea.location, dea.date, total_cases, cast(new_cases as int) as NewCases, cast(new_vaccinations as int) as NewVacs,
	Case
		When new_cases < new_vaccinations then 'More Vaccinations than Cases'
		When new_cases > new_vaccinations then 'More Cases than Vaccinations'
		When new_cases = new_vaccinations then 'Covid Cases = Vaccinations'
		When new_cases is null then 'Country not infected'
		When new_vaccinations is null then 'More Cases than Vaccines'
		else 'NULL'
	End as 'Vaccine vs Total Cases'
from CovidDeaths dea
join CovidVaccinations vac 
on dea.date = vac.date
and dea.location = vac.location
where dea.location like '%states%'



--Total Cases vs Total Deaths
--Shows likelihoood of dying if you were to contract covid in the UnitedStates
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'Death Percentage'
from PortfolioProjectCovid..CovidDeaths
where location like '%states'
order by 1,2



--Total Cases vs Population
--Shows what percentage of population got Covid
select location, date, total_cases, population, (total_cases/population)*100 as 'PercentPolulationInfected'
from PortfolioProjectCovid..CovidDeaths
where location like '%states'
order by 1,2



--Countries with highest infection rate when compared to population
select Location, Population, Max(total_cases) as 'HighestInfectionCount', Max((total_cases/population)*100) as 'PercentInfectedPopulation'
from PortfolioProjectCovid..CovidDeaths
--where location like '%states'
group by location, population
order by PercentInfectedPopulation desc



-- Countries with highest death count
select Location, Population, Max(cast(total_deaths as int)) as 'HighestDeathCount'
from PortfolioProjectCovid..CovidDeaths
where continent is not null
group by location, population
order by HighestDeathCount desc

				      

--BREAKING THINGS DOWN BY CONTINENT

--Query invalid, need to check data; however, next query provides correct numbers
----select continent, Max(cast(total_deaths as int)) as 'HighestDeathCount'
----from PortfolioProjectCovid..CovidDeaths
----where continent is not null
----group by continent
----order by HighestDeathCount desc

select location, Max(cast(total_deaths as int)) as 'HighestDeathCount'
from PortfolioProjectCovid..CovidDeaths
where continent is null
group by location
order by HighestDeathCount desc


			  
--GLOBAL NUMBERS
			  
--Total Population vs Deaths Percentage
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProjectCovid..CovidDeaths
--Where location like '%states%'
where continent is not null 
Group By date
order by 1,2


-- Total Population vs Vaccination
select dea.continent, dea.location, dea.date, population, new_vaccinations,
	Sum(cast(new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVacs
	-- (TotalVacs/Population)*100 as VaccinatedPopulation	CANNOT DO, MUST USE CTE OR TEMP TABLE 
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by continent, location

		 

--USE CTE to show Vaccinated population percentage
With PopVsVac (Contintent, Location, Date, Population, new_vaccinations, TotalVacs)
as
(
select dea.continent, dea.location, dea.date, population, new_vaccinations,
	Sum(cast(new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as TotalVacs
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by continent, location
)
Select * , (TotalVacs/Population)*100 as VaccinatedPopPercentage
from PopVsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
TotalVacs numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalVacs
--, (RollingPeopleVaccinated/population)*100
From PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (TotalVacs/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
