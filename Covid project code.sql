
-- select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM `portfolioproject-382016.Covid.Deaths` 
ORDER BY location, date;


-- Looking at total cases VS total deaths in Morocco
-- Shows the likelyhood of dying if you contract covid in Morocco
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As deaths_percentage
FROM `portfolioproject-382016.Covid.Deaths` 
WHERE location = "Morocco"
ORDER BY location, date;


-- Looking at total cases VS population in Morocco
-- Shows the likelyhood of contracting covid in Morocco
SELECT location, date, total_cases, population, (total_cases/population)*100 As cases_percentage
FROM `portfolioproject-382016.Covid.Deaths` 
WHERE location = "Morocco"
ORDER BY location, date;


--Looking at countries with the highest infection rate compared to population
SELECT location, population, max(total_cases) as highest_infection_count, (max(total_cases/population))*100 As max_infection_percentage
FROM `portfolioproject-382016.Covid.Deaths`
WHERE continent is not null --this eliminates grouped elements like(asia, africa, world...etc)
GROUP BY location, population
ORDER BY max_infection_percentage desc;


-- Showing countries with the highest death count per population
SELECT location, population, max(cast(total_deaths as int)) as total_deaths_count
FROM `portfolioproject-382016.Covid.Deaths`
WHERE continent is not null --this eliminates grouped elements like(asia, africa, world...etc)
GROUP BY location, population
ORDER BY total_deaths_count desc;


-- Showing continent with the highest death count per population
SELECT location, max(cast(total_deaths as int)) as total_deaths_count_per_continent
FROM `portfolioproject-382016.Covid.Deaths`
WHERE continent is null --this eliminates grouped elements like(asia, africa, world...etc)
GROUP BY location
ORDER BY total_deaths_count_per_continent desc;


--Showing the worldwide progression of the infection and deaths by date
SELECT date, cast(new_cases as int) as cases, cast(new_deaths as int) as deaths, cast(new_deaths as int)/cast(new_cases as int) as deaths_percentage
FROM `portfolioproject-382016.Covid.Deaths`
Where location = "World" and new_cases != 0 --to avoid division by 0 error
ORDER BY date;


--Looking at total population vs vaccination
SELECT dea.date, dea.location, dea.population, vac.new_vaccinations,
FROM `portfolioproject-382016.Covid.Vaccinations` as vac Join `portfolioproject-382016.Covid.Deaths` as dea
  on vac.location = dea.location and vac.date = dea.date
WHERE vac.new_vaccinations is not null and dea.continent is not null
ORDER BY date, vac.new_vaccinations desc;

--Shows the graduate increase in the number of vaccinations
----temp table
with total_vac_temp as(
SELECT dea.date,dea.continent, dea.location, cast(vac.new_vaccinations as int) as new_vac, 
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as total_vac,
dea.population
FROM `portfolioproject-382016.Covid.Vaccinations` as vac Join `portfolioproject-382016.Covid.Deaths` as dea
  on vac.location = dea.location and vac.date = dea.date
WHERE dea.continent is not null
)
----main query
SELECT * , (total_vac/population)*100 as percentage_vaccinated
FROM total_vac_temp
WHERE continent is not null;
