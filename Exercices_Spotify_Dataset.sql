-- create table
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);



-- 1.Retrieve the names of all tracks that have more than 1 billion streams.
SELECT 
	track
FROM spotify
WHERE stream >= 1000000000

-- 2 List all albums along with their respective artists.
SELECT 
	DISTINCT album,
			artist 
FROM spotify
ORDER BY 1

-- 3 Get the total number of comments for tracks where licensed = TRUE.

SELECT 
	SUM(comments) as total_comments
FROM spotify
WHERE licensed = 'true'

-- 4 Find all tracks that belong to the album type single.
SELECT 
	COUNT(*) as nb_single
FROM spotify
WHERE album_type = 'single'

--5 Count the total number of tracks by each artist.
SELECT 
	artist,
	COUNT(track) as nb_tracks
FROM spotify
GROUP BY artist
ORDER BY 2 DESC

-- 6 Calculate the average danceability of tracks in each album.
SELECT 
	album,
	ROUND(AVG(danceability)::numeric, 3) as avg_dance
FROM spotify
GROUP BY album
ORDER BY 2 DESC

-- 7 Find the top 5 tracks with the highest energy values.
SELECT 
	artist,
	track,
	energy
FROM spotify
ORDER BY energy DESC
LIMIT 5

-- 8 List all tracks along with their views and likes where official_video = TRUE.
SELECT 
	track,
	views,
	likes
FROM Spotify
WHERE official_video = TRUE

-- 9 For each album, calculate the total views of all associated tracks.
SELECT 
	album,
	track,
	SUM(views)
FROM Spotify
GROUP BY 1,2
ORDER BY 3 DESC

-- 10 Retrieve the track names that have been streamed on Spotify more than YouTube.
with streams as (
	SELECT
		track,
		COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) as streamed_on_youtube,
		COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) as streamed_on_spotify
	FROM spotify
	GROUP BY 1
)
SELECT 
	track
FROM streams
WHERE streamed_on_spotify > streamed_on_youtube

-- 11 Find the top 3 most-viewed tracks for each artist using window functions.
with rk as
(
SELECT
	artist,
	track,
	SUM(views) as views,
	RANK() OVER(PARTITION BY artist ORDER BY SUM(views) DESC) as rk_views
FROM spotify
GROUP BY 1,2
)
SELECT
	artist,
	track,
	views,
	rk_views
FROM rk
WHERE rk_views <= 3
ORDER BY artist, rk_views

-- 12 Write a query to find tracks where the liveness score is above the average.
SELECT
	artist,
	track,
	liveness
FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify)

-- 13  Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.
with track_diff as (
SELECT
	album,
	MAX(energy) as highest_energy,
	MIN(energy) as lowest_energy
FROM Spotify
GROUP BY 1
)
SELECT 
	album,
	highest_energy, 
	lowest_energy,
	ROUND((highest_energy - lowest_energy)::numeric, 3) as diff
FROM track_diff

-- 14 	Quels sont les artistes les plus streamés et quel pourcentage du total global représentent-ils ?
with artists_streams as (
SELECT
	artist,
	SUM(stream) as nb_streams
FROM spotify
GROUP BY artist
),
top_10 as (
	SELECT 
		artist,
		nb_streams
	FROM artists_streams
	ORDER BY 2 DESC
	LIMIT 10
),
total_artists as (
SELECT COUNT(DISTINCT artist) as total FROM spotify
)
SELECT 
	t.artist,
	t.nb_streams,
	ROUND(100.0 / total, 2) as percentage
FROM top_10 t
CROSS JOIN total_artists 

	
-- 15	Quels sont les 3 albums avec la meilleure valence moyenne parmi ceux ayant plus de 5 titres ?

SELECT 
	album,
	AVG(valence) as avg_valence
FROM spotify
GROUP BY album
HAVING COUNT(*) >= 5
ORDER BY 2 DESC
LIMIT 3

-- 16 Pour chaque artiste, quel est le morceau avec le plus grand écart entre likes et commentaires ?
with difference as (
SELECT
	artist,
	track,
	ABS(likes - comments) as diff
FROM Spotify
),
ranked as (
	SELECT *,ROW_NUMBER() OVER(PARTITION BY artist ORDER BY diff DESC) as rk
	FROM difference
)
SELECT 
	artist,
	track,
	diff
FROM ranked
WHERE rk = 1
ORDER BY diff  DESC

-- 17 Quels sont les morceaux les plus populaires en termes de ratio streams / durée (minutes) ?
SELECT
	artist, 
	track,
	stream,
	duration_min,
	stream * 1.0 / duration_min as ratio
FROM spotify
WHERE duration_min != 0
ORDER BY ratio DESC
LIMIT 15

-- 18 Quelle est la moyenne du loudness pour chaque artiste parmi les morceaux très instrumentaux (instrumentalness > 0.5) ?
SELECT 
	artist,
	AVG(loudness) as avg_loud
FROM spotify
WHERE instrumentalness > 0.5
GROUP BY artist
ORDER BY 2 DESC

-- 19 Quels sont les morceaux avec beaucoup de vues mais peu de likes (ratio views / likes élevé) ?
SELECT
	artist,
	track,
	views,
	likes,
	ROUND((views * 1.0 / likes)::numeric , 2)as ratio
FROM Spotify
WHERE likes != 0
ORDER BY ratio DESC
LIMIT 20

-- 20 Comment évolue le nombre de streams d’un artiste d’un album à l’autre (classement par album) ?
with album_streams as(
SELECT
	artist,
	album,
	SUM(stream) as total_streams
FROM Spotify
GROUP BY artist, album
),
album_rank as (
	SELECT
		artist,
		album,
		total_streams,
		ROW_NUMBER() OVER(PARTITION BY artist ORDER BY total_streams DESC) as album_order,
		LAG(total_streams) OVER(PARTITION BY artist ORDER BY total_streams DESC) as previous_album_stream
	FROM album_streams
)
SELECT 
	artist,
	album,
	total_streams,
	album_order,
	previous_album_stream,
	total_streams - previous_album_stream as diff
FROM album_rank 
ORDER BY artist, album_order

-- 21 Quels sont les albums où tous les morceaux sont marqués comme vidéos officielles (official_video = TRUE) 
SELECT
	album
FROM Spotify
GROUP BY album
HAVING COUNT(*) = SUM(CASE WHEN official_video THEN 1 ELSE 0 END)
	
-- 22  Quel est l’écart-type de l’énergie (energy) des morceaux pour chaque album ?
SELECT
	album,
	STDDEV(energy) as std_energy
FROM Spotify
WHERE energy IS NOT NULL
GROUP BY album
HAVING COUNT(energy) > 1
ORDER BY std_energy DESC


-- 23 Quels artistes ont au moins un morceau avec plus de 2 millions de vues ET un score de danceability supérieur à 0.8 ?
SELECT
	DISTINCT artist
FROM spotify
WHERE views > 2000000 AND danceability > 0.8


-- 24 Quel est le pourcentage cumulé de streams pour les 10 morceaux les plus streamés par rapport au total ?
with stream_rank as (
SELECT
	track,
	stream,
	DENSE_RANK() OVER(ORDER BY stream DESC) as rk
FROM Spotify
)
SELECT
	  ROUND(SUM(stream) * 100.0 / (SELECT SUM(stream) FROM spotify), 2) AS ratio_en_pourcentage 

FROM stream_rank
WHERE rk <= 10

-- 25 Pour chaque artiste, quel est l’écart entre le morceau le plus énergique et le moins énergique ?
with artists_energy as (
	SELECT 
		artist,
		MAX(energy) as max_energy,
		MIN(energy) as min_energy
	FROM Spotify
	GROUP BY artist
)
SELECT
	artist,
	ROUND((max_energy - min_energy)::numeric, 5) as difference
FROM artists_energy
ORDER BY 2 DESC 

-- 26 Quel est le classement global des morceaux par vues, et aussi leur rang parmi les morceaux du même album 
SELECT
		track,
		views,
		RANK() OVER(ORDER BY views DESC) as overall_rank,
		RANK() OVER(PARTITION BY album ORDER BY views DESC ) album_views_rank
FROM Spotify

-- 27. Pour chaque album, quel est le titre dont la popularité (par exemple likes + streams) est la plus faible ?
with ranked_tracks as (
SELECT
	album,
	track,
	likes + stream as stats,
	ROW_NUMBER() OVER(PARTITION BY album ORDER BY likes + stream ASC ) as rk
FROM Spotify
)
SELECT	
	album, 
	track,
	stats
FROM ranked_tracks
WHERE rk = 1

-- 28 Quel est le top 5 des artistes avec la plus forte moyenne de streams par morceau ?
SELECT
	artist,
	ROUND(AVG(stream), 1) as avg_stream
FROM Spotify
GROUP BY artist
ORDER BY  avg_stream DESC
LIMIT 5

-- 29 Pour chaque artiste, quels sont les 3 morceaux les plus longs en durée ?
with rank_artists as (
SELECT
	artist,
	track,
	duration_min,
	ROW_NUMBER() OVER(PARTITION BY artist ORDER BY duration_min DESC) as rk
FROM Spotify
)
SELECT
	artist,
	track,
	duration_min
FROM rank_artists
WHERE rk <= 3
ORDER BY artist



with rank_stream as (
SELECT 
	artist,
	track,
	stream,
	most_played_on,
	RANK() OVER(PARTITION BY most_played_on ORDER BY stream DESC) as rk
FROM Spotify
)
SELECT
	artist,
	track,
	stream,
	most_played_on
FROM rank_stream
WHERE rk = 1