
-- Set up map identifier variable 
--EXEC sp_rename 'dbo.phs-2022.esports_match_id', 'match_id', 'COLUMN';

--update dbo.[match_map_stats]
--set map_id = CONVERT(VARCHAR(10),[match_id]) + [map_name]

--update dbo.[phs-2022]
--set map_id = CONVERT(VARCHAR(10),[match_id]) + [map_name]


-- Number of maps played by Profit on each hero 
select count(hero_name) as maps_played, 
hero_name 
from(
select distinct dbo.match_map_stats.stage, dbo.[phs-2022].map_id, hero_name, player_name, dbo.[phs-2022].amount, match_map_stats.map_winner,  dbo.match_map_stats.map_loser
from dbo.[phs-2022]
join dbo.match_map_stats on dbo.[phs-2022].map_id=dbo.[match_map_stats].map_id 
where player_name='Profit' and stat_name='Time Played' and amount>60) 
as subquery
group by hero_name
ORDER BY COUNT(hero_name) DESC;


-- Number of maps played as Tracer by each player 
select count(player_name) as tracer_maps, player_name 
from(
select distinct dbo.match_map_stats.stage, dbo.[phs-2022].map_id, hero_name, player_name, dbo.[phs-2022].amount, match_map_stats.map_winner,  dbo.match_map_stats.map_loser
from dbo.[phs-2022]
join dbo.match_map_stats on dbo.[phs-2022].map_id=dbo.[match_map_stats].map_id 
where hero_name='Tracer' and stat_name='Time Played' and amount>60) 
as subquery
group by player_name
ORDER BY COUNT(player_name) DESC;


-- Average Eliminations/Life for a player on Tracer given that they are winning/losing 
SELECT 
player_name,
AVG(CASE WHEN team_name=map_winner THEN eliminations_per_life ELSE NULL END) AS avg_elimination_per_life_winner,
AVG(CASE WHEN team_name=map_loser THEN eliminations_per_life ELSE NULL END) AS avg_elimination_per_life_loser
FROM(
SELECT dbo.[phs-2022].map_id,
player_name,
hero_name,
team_name,
dbo.match_map_stats.map_winner,
dbo.match_map_stats.map_loser,
    SUM(CASE WHEN stat_name = 'Eliminations' THEN amount ELSE 0 END) / 
        (SUM(CASE WHEN stat_name = 'Deaths' THEN amount ELSE 0 END) + 1) AS eliminations_per_life
FROM dbo.[phs-2022]
JOIN dbo.match_map_stats ON dbo.[phs-2022].map_id = dbo.match_map_stats.map_id 
WHERE dbo.match_map_stats.map_round=1 and hero_name='Tracer' AND (stat_name='Eliminations' OR stat_name='Deaths') AND EXISTS (
        SELECT 1
        FROM dbo.[phs-2022] t
        WHERE t.map_id = dbo.[phs-2022].map_id 
        AND t.hero_name = dbo.[phs-2022].hero_name
        AND t.stat_name = 'Time Played'
        AND t.amount > 60
    )
GROUP BY dbo.[phs-2022].map_id, player_name, hero_name, team_name, dbo.match_map_stats.map_winner, dbo.match_map_stats.map_loser) as subquery
GROUP BY player_name
HAVING COUNT(*)>30


---- Which team did Seoul Dynasty lose to the most? 
SELECT 
    map_winner,
    COUNT(DISTINCT map_id) AS num_map_wins
FROM 
    dbo.match_map_stats
WHERE 
    map_loser = 'Seoul Dynasty' and map_round=1
GROUP BY 
    map_winner
 ORDER BY num_map_wins DESC


---- Which team did Seoul Dynasty win against the most?
SELECT 
    map_loser,
	COUNT(map_id) as num_map_losses
FROM 
    dbo.match_map_stats
WHERE 
    map_winner = 'Seoul Dynasty' and map_round=1
GROUP BY 
    map_loser
ORDER BY num_map_losses DESC


-- Which Tracer had the highest average pulse bomb stick rate accuracy? 
SELECT 
player_name,
hero_name,
AVG(amount) as avg_pulse_bomb_attach_rate
FROM dbo.[phs-2022]
WHERE stat_name='Pulse Bomb Attach Rate' and hero_name='Tracer' and EXISTS(
		SELECT 1
	    FROM dbo.[phs-2022] t
        WHERE t.map_id = dbo.[phs-2022].map_id 
        AND t.hero_name = dbo.[phs-2022].hero_name
        AND t.stat_name = 'Time Played'
        AND t.amount > 60
)
GROUP BY player_name, hero_name
HAVING COUNT(*) > 10
ORDER BY avg_pulse_bomb_attach_rate DESC


-- Which Tracer had the lowest average time elapsed per Ultimate?
SELECT 
player_name,
hero_name,
AVG(amount) as avg_time_elapsed_ultimate
FROM dbo.[phs-2022]
WHERE stat_name='Time Elapsed per Ultimate Earned' and hero_name='Tracer' and EXISTS(
		SELECT 1
	    FROM dbo.[phs-2022] t
        WHERE t.map_id = dbo.[phs-2022].map_id 
        AND t.hero_name = dbo.[phs-2022].hero_name
        AND t.stat_name = 'Time Played'
        AND t.amount > 60
)
GROUP BY player_name, hero_name
HAVING COUNT(*) > 10
ORDER BY avg_time_elapsed_ultimate 

