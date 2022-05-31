/* Data Source:  https://ourworldindata.org/covid-deaths
		1) Downloaded the dataset in CSV. It had both vaccination and deaths data in one file.
		2) Separated the data into 2 Excel files: One with Vaccination data, and then with Deaths data. Reason for that: Wanted to show the "join" code, though could have just used the file as one
 */ 

--  First section is pulling data for visualization in TABLEAU.  Second Section is to explore data and SQL CODE 

----- SECTION 1:  SAMPLE SQL CODE for TABLEAU  ----------------------
-- A: WORLDWIDE VIEW:  Pull in total cases, total deaths and %Death.  Since continent subtotals shows up as a row, we are filtering it out to avoid double count
Select SUM(new_cases) as total_cases, SUM(cast (new_deaths as Int)) as total_deaths, SUM(cast(new_deaths as int))/ sum(new_cases)*100 as DeathPercentage
From COVID_Project..CovidDeaths	 
Where continent is not null	-- To avoid double count, remove the continent aggregate in data e.g. Asia, Oceania, ... World, International. These are subtotals incl in data
Order by 1,2

-- B: CONTINENT VIEW: Note European Union is part of Europe, so need to exclude that
Select Location, SUM(CAST(new_deaths as int)) as TotalDeathCount
From COVID_Project..CovidDeaths
Where continent is null and location not in ('World', 'European Union', 'International')  -- to avoid double count from subtotals included in dataset rows
Group by location
Order by TotalDeathCount desc

-- C: LOCATION/COUNTRY VIEW:
Select Location, Population, Max(Total_Cases) as HighInfectionCount,  Max((Total_Cases/population))*100 as InfectedPopulationPercentage
From COVID_Project..CovidDeaths
Group by Location, Population
Order by InfectedPopulationPercentage desc

-- D: HIGHEST INFECTION RATE by Location/Country
Select Location, Population, Date, Max(Total_Cases) as HighInfectionCount,  Max((Total_Cases/population))*100 as InfectedPopulationPercentage
From COVID_Project..CovidDeaths
Group by Location, Population, Date
Order by InfectedPopulationPercentage desc





----- SECTION 2: SAMPLE SQL CODE TO EXPLORE DATA BELOW  ----------------------
Select *
From COVID_Project .. CovidDeaths
Where continent is not null	-- To avoid double count, remove the continent aggregate in data e.g. Asia, Oceania, ... World, International. These are subtotals incl in data
Order by 3,4

-- Select data to use for this project
Select Location, Date, total_cases, new_cases, total_deaths, population
From COVID_Project .. CovidDeaths
Order by 1,2

-- Compare Total Cases vs Total Deaths
Select Location, Date, Total_Cases, Total_Deaths, (total_deaths/total_cases)*100 as DeathPercentage
From COVID_Project..CovidDeaths	 
where location like '%states%' and continent is not null	-- To avoid double count, remove the continent aggregate in data e.g. Asia, Oceania, ... World, International. These are subtotals incl in data
Order by 1,2

-- Compare Total Cases vs Population
Select Location, Date, Total_Cases, Population, (total_cases/Population)*100 as InfectedPercentage
From COVID_Project..CovidDeaths	 
where location like '%states%' and continent is not null	-- To avoid double count, remove the continent aggregate in data e.g. Asia, Oceania, ... World, International. These are subtotals incl in data
Order by 1,2

-- Which country has the highest Infection Rate vs Population
Select Location, Population, Max(Total_Cases) as HighInfectionCount,  Max((Total_Cases/population))*100 as InfectedPopulationPercentage
From COVID_Project..CovidDeaths
Where continent is not null	-- To avoid double count, remove the continent aggregate in data e.g. Asia, Oceania, ... World, International. These are subtotals incl in data
Group by Location, Population
Order by InfectedPopulationPercentage desc


-- Which country has the highest Death Count vs Population
Select Location, Max(cast (total_deaths as int) ) as TotalDeathCount
From COVID_Project..CovidDeaths
Where continent is not null	-- To avoid double count, remove the continent aggregate in data e.g. Asia, Oceania, ... World, International. These are subtotals incl in data
Group by Location, Population
Order by TotalDeathCount desc

-- CONTINENT VIEW

-- Which CONTINENT has the highest Death Count vs Population
Select Location, Max(cast (total_deaths as int) ) as TotalDeathCount
From COVID_Project..CovidDeaths
Where continent is null
Group by Location
Order by TotalDeathCount desc 

-- WORLDWIDE VIEW
Select Date, SUM(new_cases) as total_cases, SUM(cast (new_deaths as Int)) as total_deaths, SUM(cast(new_deaths as int))/ sum(new_cases)*100 as DeathPercentage
From COVID_Project..CovidDeaths	 
Where continent is not null	-- To avoid double count, remove the continent aggregate in data e.g. Asia, Oceania, ... World, International. These are subtotals incl in data
Group By Date
Order by 1,2

-- JOIN TABLES and Compare Total Population vs Total Vaccination
Select death.continent, death.location, death.Date, Death.population, Vaccine.new_vaccinations
, SUM(CONVERT(int, vaccine.new_vaccinations)) OVER (Partition by Death.location order by death.location, death.date) as  CumulativeVaccinated
From COVID_Project..CovidDeaths death
Join COVID_Project..CovidVaccinations vaccine
	On death.location = vaccine.location
	and death.date = vaccine.date
Where death.continent is not null
Order by 2,3

-- USE CTE
With PopulationVsVaccination (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccinated) 
as
(
Select death.continent, death.location, death.Date, Death.population, Vaccine.new_vaccinations
, SUM(CONVERT(int, vaccine.new_vaccinations)) OVER (Partition by Death.location order by death.location, death.date) as  CumulativeVaccinated
From COVID_Project..CovidDeaths death
Join COVID_Project..CovidVaccinations vaccine
	On death.location = vaccine.location
	and death.date = vaccine.date
Where death.continent is not null
) --Order by 2,3

Select *, (CumulativeVaccinated/Population) * 100
From PopulationVsVaccination


-- STORE DATA for visualization

Create View PercentPopVaccinated as 

Select death.continent, death.location, death.Date, Death.population, Vaccine.new_vaccinations
, SUM(CONVERT(int, vaccine.new_vaccinations)) OVER (Partition by Death.location order by death.location, death.date) as  CumulativeVaccinated
From COVID_Project..CovidDeaths death
Join COVID_Project..CovidVaccinations vaccine
	On death.location = vaccine.location
	and death.date = vaccine.date
Where death.continent is not null
