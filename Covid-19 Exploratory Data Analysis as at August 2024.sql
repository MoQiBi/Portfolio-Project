#IMPORTING DATA (PowerShell)
DROP TABLE IF EXISTS covid_vaccinations;
CREATE TABLE covid_vaccinations (
iso_code TEXT,
continent TEXT,
location TEXT,
`date` TEXT,
new_tests INT,
total_tests_per_thousand DECIMAL,
new_tests_per_thousand DECIMAL,
new_tests_smoothed DECIMAL,
new_tests_smoothed_per_thousand DECIMAL,
positive_rate INT,
tests_per_case DECIMAL,
tests_units TEXT,
total_vaccinations BIGINT,
people_vaccinated INT,
people_fully_vaccinated INT,
total_boosters BIGINT,
new_vaccinations BIGINT,
new_vaccinations_smoothed BIGINT,
total_vaccinations_per_hundred DECIMAL,
people_vaccinated_per_hundred DECIMAL,
people_fully_vaccinated_per_hundred DECIMAL,
total_boosters_per_hundred DECIMAL,
new_vaccinations_smoothed_per_million INT,
new_people_vaccinated_smoothed INT,
new_people_vaccinated_smoothed_per_hundred INT,
stringency_index DECIMAL,
population_density DECIMAL,
median_age DECIMAL,
aged_65_older DECIMAL,
aged_70_older DECIMAL,
gdp_per_capita DECIMAL,
extreme_poverty DECIMAL,
cardiovasc_death_rate DECIMAL,
diabetes_prevalence DECIMAL,
female_smokers DECIMAL,
male_smokers DECIMAL,
handwashing_facilities DECIMAL,
hospital_beds_per_thousand DECIMAL,
life_expectancy DECIMAL,
human_development_index DECIMAL,
population BIGINT,
excess_mortality_cumulative_absolute DECIMAL,
excess_mortality_cumulative DECIMAL,
excess_mortality DECIMAL,
excess_mortality_cumulative_per_million DECIMAL
);

-- SHOW VARIABLES LIKE "local_infile";
-- SET GLOBAL local_infile=1;

load data local infile 'C:\\Users\\Dell\\Downloads\\CovidVaccinations.csv'
INTO TABLE covid_vaccinations 
fields terminated by ','
ignore 1 rows;

# SELECT `date`
# FROM covid_vaccinations ;


DROP TABLE IF EXISTS covid_deaths;
CREATE TABLE covid_deaths (
iso_code TEXT,
continent TEXT,
location TEXT,
`date` TEXT,
population bigint,
total_cases int,
new_cases bigint,
new_cases_smoothed DECIMAL,
total_deaths bigint,
new_deaths INT,
new_deaths_smoothed DECIMAL,
total_cases_per_million DECIMAL,
new_cases_per_million DECIMAL,
new_cases_smoothed_per_million DECIMAL,
total_deaths_per_million DECIMAL,
new_deaths_per_million DECIMAL,
new_deaths_smoothed_per_million DECIMAL,
reproduction_rate DECIMAL,
icu_patients INT,
icu_patients_per_million DECIMAL,
hosp_patients bigint,
hosp_patients_per_million DECIMAL,
weekly_icu_admissions BIGINT,
weekly_icu_admissions_per_million DECIMAL,
weekly_hosp_admissions bigint,
weekly_hosp_admissions_per_million DECIMAL
);

load data local infile 'C:\\Users\\Dell\\Downloads\\CovidDeaths.csv'
INTO TABLE covid_deaths 
fields terminated by ','
ignore 1 rows;

ALTER TABLE covid_deaths
MODIFY COLUMN `date` date;
ALTER TABLE covid_vaccinations
MODIFY COLUMN `date` date;

SELECT * 
FROM covid_deaths cd
ORDER BY 3, 4
;

SELECT * 
FROM covid_vaccinations cv
ORDER BY 3, 4;

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





