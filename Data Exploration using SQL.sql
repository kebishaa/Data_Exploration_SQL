SELECT *
FROM [Coronavirus Deaths].dbo.CovidDeaths
Where Continent is not null
ORDER BY 3,4


--SELECT *
--FROM [Coronavirus Deaths].dbo.CovidVaccinations
--ORDER BY 3,4

--select data that are going to be used

Select location, date, total_cases, new_cases, total_deaths, population
From [Coronavirus Deaths].dbo.CovidDeaths
Where Continent is not null
order by 1,2

-- loking at total cases vs total deaths
-- showa likelyhood of dying if you contract covid in your country

SELECT 
    location, 
    date, 
    total_cases,  
    total_deaths, 
    CAST(total_deaths AS FLOAT)*100 / CAST(total_cases AS FLOAT)*100 AS DeathPercentage
FROM [Coronavirus Deaths].dbo.CovidDeaths
where location like '%states%'
and Continent is not null
ORDER BY 1, 2;

-- Looking at Total Cases vs Population
-- shows wht percentage of population got covid 


SELECT 
    location, 
    date, 
    total_cases,  
    population, 
    CAST(population AS FLOAT)*100 / CAST(total_cases AS FLOAT)*100 AS PercentagePopulationInfected
FROM [Coronavirus Deaths].dbo.CovidDeaths
--where location like '%states%'
Where Continent is not null
ORDER BY 1, 2;

-- Looking at Countries with Highest Infection Rate Compared to Population


SELECT 
    location,
	 population,
   MAX(total_cases) AS HighestInfectionCount,   
    CAST(population AS FLOAT)*100 / CAST(MAX(total_cases) AS FLOAT)*100 AS PercentagePopulationInfected
FROM [Coronavirus Deaths].dbo.CovidDeaths
--where location like '%states%'
Where Continent is not null
Group by location, population
ORDER BY PercentagePopulationInfected desc

-- showing the countries with highest death count per popultion

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From [Coronavirus Deaths].dbo.CovidDeaths
Where Continent is not null
Group by location
order by TotalDeathCount desc

-- let's break things down by continent

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From [Coronavirus Deaths].dbo.CovidDeaths
Where Continent is not null
Group by continent
order by TotalDeathCount desc

-- Global Numbers



SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    (SUM(CAST(new_deaths AS INT)) * 100.0 / SUM(new_cases)) AS DeathPercentage
FROM 
    [Coronavirus Deaths].[dbo].[CovidDeaths]
WHERE 
    continent IS NOT NULL
ORDER BY 
    total_cases, total_deaths;


-- looking at total populations vs vaccination
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From [Coronavirus Deaths].dbo.CovidDeaths dea
Join [Coronavirus Deaths].dbo.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM 
        [Coronavirus Deaths]..CovidDeaths dea
    JOIN 
        [Coronavirus Deaths]..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL 
    --, (RollingPeopleVaccinated/population)*100
)
SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationRate
FROM 
    PopvsVac;


	-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Coronavirus Deaths]..CovidDeaths dea
Join [Coronavirus Deaths]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    [Coronavirus Deaths]..CovidDeaths dea
JOIN 
    [Coronavirus Deaths]..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

