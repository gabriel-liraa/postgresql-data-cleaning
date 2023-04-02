DROP TABLE IF EXISTS data;
CREATE TABLE data (
	name VARCHAR(255),
	author VARCHAR(255),
	narrator VARCHAR(255),
	time VARCHAR(255),
	releasedate VARCHAR(255),
	language VARCHAR(255),
	stars VARCHAR(255),
	price VARCHAR(255)
);

COPY data
FROM 'path/to/audible_uncleaned.csv' DELIMITER ',' CSV HEADER;

DELETE FROM data
WHERE language <> 'English';

DROP TABLE IF EXISTS cleaned_table;
CREATE TABLE cleaned_table AS (
	-- Declarando CTE's
	
	-- Dados originaIS numerados
	WITH numbered_data AS (
    SELECT *, ROW_NUMBER() OVER() AS num
    FROM data
	),
	-- Dados de autores tratados
	cleaned_author_select AS (
		SELECT TRIM(TRAILING ',' FROM REPLACE(author, 'Writtenby:', '')) AS cleaned_author
		FROM data
	),
	-- Dados de autores tratados convertidos em arrays
	arrays_author AS (
		SELECT STRING_TO_ARRAY(cleaned_author, ',') AS arrays
		FROM cleaned_author_select
	),
	-- Dados de autores tratados separados em 1 coluna por autor
	separated_columns_author AS (
		SELECT
			CASE WHEN arrays[1] IS NOT NULL THEN arrays[1] ELSE NULL END AS author_1,
			CASE WHEN arrays[2] IS NOT NULL THEN arrays[2] ELSE NULL END AS author_2,
			CASE WHEN arrays[3] IS NOT NULL THEN arrays[3] ELSE NULL END AS author_3,
			ROW_NUMBER() OVER() AS num
		FROM arrays_author
	),
	-- Dados de narradores tratados
	cleaned_narrator_select AS (
		SELECT TRIM(TRAILING ',' FROM REPLACE(narrator, 'Narratedby:', '')) AS cleaned_narrator
		FROM data
	),
	-- Dados de narradores tratados convertidos em arrays
	arrays_narrator AS (
		SELECT STRING_TO_ARRAY(cleaned_narrator, ',') AS arrays
		FROM cleaned_narrator_select
	),
	-- Dados de narradores tratados separados em 1 coluna por autor
	separated_columns_narrator AS (
		SELECT
			CASE WHEN arrays[1] IS NOT NULL THEN arrays[1] ELSE NULL END AS narrator_1,
			CASE WHEN arrays[2] IS NOT NULL THEN arrays[2] ELSE NULL END AS narrator_2,
			CASE WHEN arrays[3] IS NOT NULL THEN arrays[3] ELSE NULL END AS narrator_3,
			ROW_NUMBER() OVER() AS num
		FROM arrays_narrator
	)
	
	SELECT
	
	-- name
	
		name,
	
	-- author
	
		author_1, author_2, author_3,
			
	-- narrator 
	
		narrator_1, narrator_2, narrator_3,
		
	-- time
	
		CAST(CASE
			WHEN time ~ '^\d{1,3}( mins?| hrs?| hrs? and \d{1,2} mins?)$'
			THEN EXTRACT(EPOCH FROM REPLACE(time, 'and ', '')::INTERVAL)/60
			ELSE 0
		END AS DECIMAL(4, 0)) AS duration,
		
	-- releasedate
	
		TO_DATE(releasedate, 'DD-MM-YY') AS releasedate,
		
	-- stars
	
		CAST(CASE
			WHEN stars ~ '([0-5]{1}(.\d{1})?)' THEN SPLIT_PART(stars, ' ', 1)
			ELSE NULL
		END AS DECIMAL(2, 1)) AS stars,
		
	-- ratings
	
		CAST(CASE
			WHEN stars ~ '(stars\d{1,3}(,\d{3})*)' 
			THEN REPLACE(LTRIM(SUBSTRING(stars FROM '(stars\d{1,3}(,\d{3})*)'), 'stars'), ',', '')
			ELSE '0'
		END AS integer) AS ratings,
		
	-- price
	
		CAST(CASE 
			WHEN price !~ '(\d{1,3}(,\d{3})?\.\d{2})' THEN '0.00'
			ELSE REPLACE(price,',', '')
		END AS DECIMAL(6, 2)) AS price
		
	FROM numbered_data
	JOIN separated_columns_narrator USING(num)
	JOIN separated_columns_author USING(num)
);

COPY cleaned_table TO 'path/to/audible_cleaned.csv' DELIMITER ',' CSV HEADER;