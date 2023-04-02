SELECT * FROM data;

-- Procurando valores nulos

SELECT *
FROM data
WHERE name IS NULL OR
	author IS NULL OR
	narrator IS NULL OR
	time IS NULL OR
	releasedate IS NULL OR
	language IS NULL OR
	stars IS NULL OR
	price IS NULL;
	
-- ======================= price =======================

-- Procurando por dados fora do padrão

SELECT DISTINCT price
FROM data
WHERE price !~ '^(\d{1,3}(,\d{3})?\.\d{2})';

-- Convertendo o a coluna price para o tipo decinaml, e tratando ocorrências de 'Free'

SELECT 
CAST(CASE 
	WHEN price !~ '(\d{1,3}(,\d{3})?\.\d{2})' THEN '0.00'
	ELSE REPLACE(price,',', '')
END AS DECIMAL(6, 2)) AS price
FROM data;

-- =====================================================

-- ======================= stars =======================

-- Procurando por dados fora do padrão

SELECT DISTINCT stars
FROM data
WHERE stars !~ '^([0-5]{1}(.\d{1})?) out of 5 stars((\d{1,3},)?\d{1,3}) rating[s]?$';

-- Retirando AS ocorrências de ',' e separando AS informações de stars e ratings, de tipo decimal e int respectivamente

SELECT 
	CAST(CASE
		WHEN stars ~ '([0-5]{1}(.\d{1})?)' THEN SPLIT_PART(stars, ' ', 1)
		ELSE NULL
	END AS DECIMAL(2, 1)) AS stars,
	CAST(CASE
		WHEN stars ~ '(stars\d{1,3}(,\d{3})*)' 
		THEN REPLACE(LTRIM(SUBSTRING(stars FROM '(stars\d{1,3}(,\d{3})*)'), 'stars'), ',', '')
		ELSE '0'
	END AS INTEGER) AS ratings
FROM data;

-- =====================================================

-- =================== releasedate ====================

-- Procurando por dados fora do padrão

SELECT DISTINCT releasedate
FROM data
WHERE releasedate !~ '\d{2}-\d{2}-\d{2}';

-- Convertendo a coluna price para o tipo data

SELECT TO_DATE(releasedate, 'DD-MM-YY')
FROM data;

-- =====================================================

-- ======================= time ========================

-- Procurando por dados fora do padrão

SELECT DISTINCT time 
FROM data
WHERE time !~ '^\d{1,3}( mins?| hrs?| hrs? and \d{1,2} mins?)$';

-- Convertendo a coluna 'time' para a duração em minutos

SELECT 
	CAST(CASE
		WHEN time ~ '^\d{1,3}( mins?| hrs?| hrs? and \d{1,2} mins?)$'
		THEN EXTRACT(EPOCH FROM REPLACE(time, 'and ', '')::INTERVAL)/60
		ELSE 0
	END AS DECIMAL(4, 0)) AS duration
FROM data;
	
-- =====================================================

-- ====================== author =======================

-- Procurando por dados fora do padrão

SELECT DISTINCT author
FROM data
WHERE author !~ '^Writtenby:[A-Za-z]+';

-- Procurando por campos com mais de um autor

SELECT DISTINCT author
FROM data
WHERE author ~ '^Writtenby:[A-Za-z]+(,[A-Za-z]+)+';

-- Separando os diferentes autores em um campo, em índices de um array

WITH cleaned_author_select AS (
	SELECT TRIM(TRAILING ',' FROM REPLACE(author, 'Writtenby:', '')) AS cleaned_author
	FROM data),
	
arrays_author AS (
SELECT STRING_TO_ARRAY(cleaned_author, ',') AS arrays
FROM cleaned_author_select),

separated_columns_author AS (
SELECT
	CASE WHEN arrays[1] IS NOT NULL THEN arrays[1] ELSE NULL END AS author_1,
	CASE WHEN arrays[2] IS NOT NULL THEN arrays[2] ELSE NULL END AS author_2,
	CASE WHEN arrays[3] IS NOT NULL THEN arrays[3] ELSE NULL END AS author_3
FROM arrays_author)

SELECT *
FROM separated_columns_author;

-- =====================================================

-- ===================== narrator ======================

-- Procurando por dados fora do padrão

SELECT DISTINCT narrator
FROM data
WHERE narrator !~ '^Narratedby:[A-Za-z]+';

-- Separando os diferentes narradores em um campo, em índices de um array
-- Os tratamentos para esse campo serão os mesmos do campo 'author'

WITH cleaned_narrator_select AS (
	SELECT TRIM(TRAILING ',' FROM REPLACE(narrator, 'Narratedby:', '')) AS cleaned_narrator
	FROM data),
	
arrays_narrator AS (
SELECT STRING_TO_ARRAY(cleaned_narrator, ',') AS arrays
FROM cleaned_narrator_select),

separated_columns_narrator AS (
SELECT
	CASE WHEN arrays[1] IS NOT NULL THEN arrays[1] ELSE NULL END AS narrator_1,
	CASE WHEN arrays[2] IS NOT NULL THEN arrays[2] ELSE NULL END AS narrator_2,
	CASE WHEN arrays[3] IS NOT NULL THEN arrays[3] ELSE NULL END AS narrator_3
FROM arrays_narrator)

SELECT * FROM separated_columns_narrator;

SELECT * FROM cleaned_table;
