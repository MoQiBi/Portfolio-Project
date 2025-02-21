-- select data that we are using 

Select location, `date`, total_cases, new_cases, total_deaths, population, continent
FROM covid_deaths
ORDER BY 1,2;

-- Looking at total cases and total deaths
-- Shows likelihood of dying if you contract covid in Malaysia from 2020/01-2024/08
SELECT location, `date`, total_cases, total_deaths, (total_deaths/total_cases) *100 as death_percentage
FROM covid_deaths
WHERE location = 'MALAYSIA'
ORDER BY 1, 2;

-- Looking at total cases and population
SELECT location, `date`, total_cases, population, (total_cases/population)*100 as 'covid%'
FROM covid_deaths
WHERE location = 'Malaysia' AND `date`= '2022-12-31'
ORDER BY 1,2;

-- Looking at countries with respective cases
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as '%PopulationInfected'
FROM covid_deaths
WHERE NOT continent = ''
GROUP BY location, population
ORDER BY '%PopulationInfected' DESC;

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as '%PopulationInfected'
FROM covid_deaths
WHERE NOT continent = ''
GROUP BY location, population
ORDER BY HighestInfectionCount DESC;

-- excluding continents
SELECT DISTINCT continent
FROM covid_deaths;

SELECT location, MAX(total_deaths) as TotalDeathCount 
FROM covid_deaths
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Showing Countries with highest DeathCount per Population 
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM covid_deaths
WHERE continent is not null AND continent <> ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Numbers by Continents and Categories
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM covid_deaths
WHERE continent is null OR continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global Numbers per day
Select location, `date`, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent <> ''
ORDER BY 1,2;

SELECT `date`, sum(new_cases) as global_cases, SUM(new_deaths) as global_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage
FROM covid_deaths
WHERE NOT continent = '' 
GROUP BY `date`
HAVING sum(new_cases) <> 0 AND SUM(new_deaths) <> 0 
ORDER BY `date`, global_cases, global_deaths ;

SELECT sum(new_cases) as global_cases, SUM(new_deaths) as global_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM covid_deaths
WHERE NOT continent = '';

-- Looking at Total Vaccinations vs Population
SELECT *
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.`date` = vac.`date`;
    
SELECT dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.`date`) as RollingVaccinated					#BuatRollingCount over partition by location, date
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.`date` = vac.`date`
WHERE NOT dea.continent = ''
ORDER BY 2, `date` ASC;

-- USE CTE
WITH Pop_vs_Vacs (Continent, Location, `date`, Population, New_Vacs, RollingVaccinated)
as
(
SELECT 
dea.continent, 
	dea.location, dea.`date`, 
	dea.population, 
    vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.`date`) as RollingVaccinated		#BuatRollingCount over partition by location, date
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.`date` = vac.`date`
WHERE NOT dea.continent = ''
ORDER BY 2, `date` ASC
)
Select * , (RollingVaccinated/Population)*100 as '%peoplevaccinated' 
FROM Pop_vs_Vacs;


WITH Pop_vs_Vacs (Continent, Location, `date`, Population, New_Vacs, RollingVaccinated) AS 
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.`date`, 
        dea.population, 
        vac.new_vaccinations, 
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.`date` ASC
        ) AS RollingVaccinated  
    FROM covid_deaths dea
    JOIN covid_vaccinations vac
        ON dea.location = vac.location
        AND dea.`date` = vac.`date`
    WHERE NOT dea.continent = ''
)
SELECT *, 
       (RollingVaccinated / Population) * 100 AS '%peoplevaccinated' 
FROM Pop_vs_Vacs
WHERE `date` = '2024-08-04';

-- Showing Global Vaccinations 
SELECT dea.location, dea.`date`, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (ORDER BY dea.`date`) as Global_Vaccinations					#BuatRollingCount over partition by date
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.`date` = vac.`date`
WHERE dea.location = 'World'
ORDER BY 2, `date` ASC;


-- USE TEMP TABLE
-- PopulationVaccinated by Country
DROP TABLE IF EXISTS PopulationVaccinated;
CREATE TEMPORARY TABLE PopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
`Date` date, 
Population bigint,
New_Vaccinations int, 
RollingVaccinated bigint
);

INSERT INTO PopulationVaccinated
SELECT dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.`date`) as RollingVaccinated				
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.`date` = vac.`date`
WHERE NOT dea.continent = ''
-- ORDER BY 2, `date` ASC;
;

Select *, (RollingVaccinated/Population)*100 as PercentageVaccinated 
FROM PopulationVaccinated
WHERE `date` = '2024-08-04';

-- CREATING VIEW FOR DATA VISUALIZATIONS
CREATE VIEW PercentPopuVacs AS
SELECT dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.`date`) as RollingVaccinated				
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.`date` = vac.`date`
WHERE NOT dea.continent = ''
ORDER BY 2, `date` ASC;

Select * 
FROM percentpopuvacs;

-- Queries used fro Tableau Project
-- 1.
SELECT sum(new_cases) as global_cases, SUM(new_deaths) as global_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM covid_deaths
WHERE NOT continent = '';

-- 2 

SELECT location, SUM(new_deaths) as TotalDeathCountperContinent
FROM covid_deaths
WHERE continent = '' AND location not in (
'World',
'European Union (27)',
'High-income countries',
'Low-income countries',
'Lower-middle-income countries',
'Upper-middle-income countries'
) 
GROUP BY continent, location;

-- finding continents to exclude
SELECT location
FROM covid_deaths
WHERE continent = ''
GROUP BY location;

-- 3 
-- percentage of infected per location
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as '%PopulationInfected'
FROM covid_deaths
WHERE NOT continent = ''
GROUP BY location, population
ORDER BY HighestInfectionCount DESC;

-- 4
-- Percentage of cases per day
Select location, population, `date`, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as '%PopulationInfected'
FROM covid_deaths
WHERE NOT continent = ''
GROUP BY location, population, `date`
ORDER BY '%PopulationInfected' DESC ;





