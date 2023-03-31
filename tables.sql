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
FROM '/home/gabriellira/Documentos/Dados/audible_cleaning/audible_uncleaned.csv' DELIMITER ',' CSV HEADER;

create table cleaned_table as (
	-- Declarando CTE's
	
	-- Dados originais numerados
	with numbered_data as (
    select *, row_number() over() as num
    from data
	),
	-- Dados de autores tratados
	cleaned_author_select as (
		select trim(trailing ',' from replace(author, 'Writtenby:', '')) as cleaned_author
		from data
	),
	-- Dados de autores tratados convertidos em arrays
	arrays_author as (
		select string_to_array(cleaned_author, ',') as arrays
		from cleaned_author_select
	),
	-- Dados de autores tratados separados em 1 coluna por autor
	separated_columns_author as (
		select
			case when arrays[1] is not null then arrays[1] else null end as author_1,
			case when arrays[2] is not null then arrays[2] else null end as author_2,
			case when arrays[3] is not null then arrays[3] else null end as author_3,
			row_number() over() as num
		from arrays_author
	),
	-- Dados de narradores tratados
	cleaned_narrator_select as (
		select trim(trailing ',' from replace(narrator, 'Narratedby:', '')) as cleaned_narrator
		from data
	),
	-- Dados de narradores tratados convertidos em arrays
	arrays_narrator as (
		select string_to_array(cleaned_narrator, ',') as arrays
		from cleaned_narrator_select
	),
	-- Dados de narradores tratados separados em 1 coluna por autor
	separated_columns_narrator as (
		select
			case when arrays[1] is not null then arrays[1] else null end as narrator_1,
			case when arrays[2] is not null then arrays[2] else null end as narrator_2,
			case when arrays[3] is not null then arrays[3] else null end as narrator_3,
			row_number() over() as num
		from arrays_narrator
	)
	
	select
	
	-- name
	
		name,
	
	-- author
	
		author_1, author_2, author_3,
			
	-- narrator 
	
		narrator_1, narrator_2, narrator_3,
		
	-- time
	
		cast(case
			when time ~ '^\d{1,3}( mins?| hrs?| hrs? and \d{1,2} mins?)$'
			then extract(epoch from replace(time, 'and ', '')::interval)/60
			else 0
		end as decimal(4, 0)) as duration,
		
	-- releasedate
	
		to_date(releasedate, 'DD-MM-YY') as releasedate,
		
	-- stars
	
		cast(case
			when stars ~ '([0-5]{1}(.\d{1})?)' then split_part(stars, ' ', 1)
			else null
		end as decimal(2, 1)) as stars,
		
	-- ratings
	
		cast(case
			when stars ~ '(stars\d{1,3}(,\d{3})*)' 
			then replace(ltrim(substring(stars from '(stars\d{1,3}(,\d{3})*)'), 'stars'), ',', '')
			else '0'
		end as integer) as ratings,
		
	-- price
	
		cast(case 
			when price !~ '(\d{1,3}(,\d{3})?\.\d{2})' then '0.00'
			else replace(price,',', '')
		end as decimal(6, 2)) as price
		
	from numbered_data
	join separated_columns_narrator using(num)
	join separated_columns_author using(num)
);