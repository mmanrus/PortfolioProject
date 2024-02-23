
SELECT * FROM PortfolioProject..CovidDeaths
	order by 3, 4;

SELECT * FROM PortfolioProject..CovidVacinations
	order by 3, 4;

--Select data that we are going to be using

--FROM Any COUNTRY:
SELECT location, max(date) AS latest, max(new_cases) AS highest_record_of_new_cases, MAX(TRY_CAST(total_cases AS int)) AS Total_cases, MAX(TRY_CAST(total_deaths AS int)) AS total_deaths, MAX(population) AS population
FROM PortfolioProject..CovidDeaths 
WHERE location LIKE '%philippines%' --e.g
--AND continent is not NULL
GROUP BY location
ORDER BY 1, 2;

-- LOOKING AT TOTAL CASES VS TOTAL DEATH

SELECT location, 
date,
total_cases,
total_deaths,
(TRY_CAST(total_deaths AS float)/TRY_CAST(total_cases AS float)) * 100 as death_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1, 2;

-- LOOKING AT TOTAL CASES VS Population

SELECT location, 
date,
total_cases,
population,
(TRY_CAST(total_cases AS float)/TRY_CAST(population AS float)) * 100 as infection_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1, 2;



--GROUPED BY COUNTRY
SELECT location AS COUNTRY, MAX(date) AS latest_report, 
MAX(TRY_CAST(total_cases AS int)) total_cases,
MAX(TRY_CAST(total_deaths AS int)) AS total_deaths
FROM PortfolioProject..CovidDeaths 
WHERE continent is not NULL
GROUP BY location
ORDER BY 1,2;


-- LOOKING AT COUNTRIES WITH HIGHEST INFECTION_RATE compared to popluation

SELECT location, 
MAX(population) AS Population,
MAX(total_cases) AS Highest_Infection_Count,
MAX(TRY_CAST(total_cases AS float)/TRY_CAST(population AS float)) * 100 as infectedPopulation_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location, Population
ORDER BY infectedPopulation_rate DESC;

--Showing Countries with Highest Death Count

SELECT
location,
MAX(population) AS Population,
MAX(TRY_CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location--, total_death_count
ORDER BY total_death_count DESC


--Showing Continent with Highest Death Count
SELECT
continent,
MAX(TRY_CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY total_death_count DESC;

--Total Deaths - Global 
SELECT 
SUM(new_cases) AS Total_Cases,
SUM(TRY_CAST(new_deaths AS INT)) AS Total_Deaths,
SUM(TRY_CAST(new_deaths AS INT)) /SUM(new_cases)*100 AS Death_Percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
--GROUP BY date

-- Looking at Total Population vs Vaccinations

SELECT 
    Dea.continent,
    Dea.location,
    Dea.date,
    Dea.population,
    Vac.new_vaccinations,
	CASE
		WHEN SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date) IS NULL 
		THEN 0
		ELSE SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date)
	END AS Cumulative_Vaccinations
FROM 
    PortfolioProject.dbo.CovidDeaths AS Dea
JOIN 
    PortfolioProject.dbo.CovidVaccinations AS Vac
    ON  Dea.location = Vac.location
    AND Dea.date = Vac.date
WHERE 
    Dea.continent IS NOT NULL
ORDER BY 
    Dea.continent, Dea.location, Dea.date;

	--Use CTE
WITH PopulationVsVaccinated (continent, date, location, population, new_vaccinations, Cumulative_Vaccinations)

AS
(
	SELECT 
		Dea.continent,
		Dea.location,
		Dea.date,
		Dea.population,
		Vac.new_vaccinations,
		CASE
			WHEN SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date) IS NULL 
			THEN 0
			ELSE SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date)
		END AS Cumulative_Vaccinations
	FROM 
		PortfolioProject.dbo.CovidDeaths AS Dea
	JOIN 
		PortfolioProject.dbo.CovidVaccinations AS Vac
		ON  Dea.location = Vac.location
		AND Dea.date = Vac.date
	WHERE 
		Dea.continent IS NOT NULL
	
	--	Dea.continent, Dea.location, Dea.date;
)
SELECT *, (Cumulative_Vaccinations/population)*100 AS Cumulative_Rate
FROM PopulationVsVaccinated;

--	DROP TEMP TABLE
DROP TABLE IF Exists #PercentPopulationVaccinated;
--	Create TEMP Table
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
Cumulative_Vaccinations numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
		Dea.continent,
		Dea.location,
		Dea.date,
		Dea.population,
		Vac.new_vaccinations,
		CASE
			WHEN SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date) IS NULL 
			THEN 0
			ELSE SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date)
		END AS Cumulative_Vaccinations
	FROM 
		PortfolioProject.dbo.CovidDeaths AS Dea
	JOIN 
		PortfolioProject.dbo.CovidVaccinations AS Vac
		ON  Dea.location = Vac.location
		AND Dea.date = Vac.date
	WHERE 
		Dea.continent IS NOT NULL
	
	--	Dea.continent, Dea.location, Dea.date;
SELECT *, (Cumulative_Vaccinations/population)*100 AS Cumulative_Rate
	FROM #PercentPopulationVaccinated;


	-- Create View to store data for later Visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
		Dea.continent,
		Dea.location,
		Dea.date,
		Dea.population,
		Vac.new_vaccinations,
		CASE
			WHEN SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date) IS NULL 
			THEN 0
			ELSE SUM(CAST(Vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY Dea.location ORDER BY Dea.date)
		END AS Cumulative_Vaccinations
	FROM 
		PortfolioProject.dbo.CovidDeaths AS Dea
	JOIN 
		PortfolioProject.dbo.CovidVaccinations AS Vac
		ON  Dea.location = Vac.location
		AND Dea.date = Vac.date
	WHERE 
		Dea.continent IS NOT NULL;
	--ORDER BY
		--Dea.continent, Dea.location, Dea.date;

SELECT * FROM PercentPopulationVaccinated;