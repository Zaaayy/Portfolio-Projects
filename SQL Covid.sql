--Select data for insights

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Order By Location, date

--Result shows some continents are registered as Location and where not as location, continent is null. Adjustments will be made to every script

-- Compare total cases vs total deaths

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 Death_Percent
From Coviddeaths
Where Continent is not null
Order By location, date

--Percentage of population that has got covid

Select location, date, total_cases, population, (total_deaths/population)*100 Covid_Percent
From Coviddeaths
Where Continent is not null
Order By location, date

-- Countries with Highest Infection Rate compared to population

Select location, Population, MAX(total_cases) HighestInfection, Max((total_Cases/population))*100 HighestInfectionRate
From [dbo].[CovidDeaths]
Where total_cases is not null and population is not null and Continent is not null
Group BY Location, Population
Order By HighestInfectionRate Desc

--Countries with Highest Death Count Per Population
--Total_deaths is an Nvarchar data type and can't be used in aggregate function

Select location, MAX(Cast(total_deaths as Int)) HighestDeaths, (Max(Cast(total_deaths as int)/population))*100 HighestDeathRate
From [dbo].[CovidDeaths]
Where Continent is not null
Group BY Location
Order By HighestDeathRate Desc

-- Global Numbers
Select continent, MAX(Cast(total_deaths as Int)) HighestDeaths, (Max(Cast(total_deaths as int)/population))*100 HighestDeathRate
From [dbo].[CovidDeaths]
Where Continent is not null
Group BY continent
Order By HighestDeathRate Desc

Select sum(new_cases) totalcases, Sum(Cast(new_deaths as Int)) totaldeaths, Sum(Cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From CovidDeaths
Where Continent is not null
Order By totalcases, totaldeaths

-- Looking into vaccinations table
Select *
From [dbo].[CovidVaccinations]

-- Total Population vs Total Vaccinations

Select CD.Location, CD.continent, CD.date, CD.Population, CV.new_vaccinations
From [dbo].[CovidDeaths] CD
Join [dbo].[CovidVaccinations] CV
On CD.date = CV.date and CD.iso_code = CV.iso_code
Where CD.continent is not null
Order By CD.Location, CD.date

-- Calculate the moving count of new vaccinations

Select CD.Location, CD.continent, CD.date, CD.Population, CV.new_vaccinations, Sum(Convert( Int, CV.New_Vaccinations)) over (Partition By CD.Location Order By CD.Location, CD.date) as MovingPeopleVaccinated
From [dbo].[CovidDeaths] CD
Join [dbo].[CovidVaccinations] CV
On CD.date = CV.date and CD.iso_code = CV.iso_code
Where CD.continent is not null
Order By CD.Location, CD.date

--To know the number of people vaccinated in a country using the moving count of new vaccinations

Select CD.Location, CD.continent, CD.date, CD.Population, CV.new_vaccinations, Sum(Convert( Int, CV.New_Vaccinations)) over (Partition By CD.Location Order By CD.Location, CD.date) as MovingPeopleVaccinated
From [dbo].[CovidDeaths] CD
Join [dbo].[CovidVaccinations] CV
On CD.date = CV.date and CD.iso_code = CV.iso_code
Where CD.continent is not null
Order By CD.Location, CD.date

--Divide Population by Moving people vaccinated to know the number of people vaccinated in a country. CTE is used because the diving cannot be made using 'MovingPeopleVaccinated' directly

With VaccinatedPopulation as (Select CD.Location, CD.continent, CD.date, CD.Population, CV.new_vaccinations, Sum(Convert( Int, CV.New_Vaccinations)) over (Partition By CD.Location Order By CD.Location, CD.date) as MovingPeopleVaccinated
From [dbo].[CovidDeaths] CD
Join [dbo].[CovidVaccinations] CV
On CD.date = CV.date and CD.iso_code = CV.iso_code
Where CD.continent is not null)

Select location, population,(MovingPeopleVaccinated/population) * 100 VaccinatedPeopleRate
From VaccinatedPopulation

--Percentage of ICU patients to death
Select location, total_deaths, icu_patients, (Max(cast(icu_patients as int))/Max(cast(total_deaths as int)))*100
From [dbo].[CovidDeaths]
Where continent is not null and icu_patients is not null and total_deaths is not null
Group By location, total_deaths, icu_patients


