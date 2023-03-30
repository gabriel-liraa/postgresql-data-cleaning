select * from data;

-- Procurando valores nulos

select *
from data
where name is null or
	author is null or
	narrator is null or
	time is null or
	realeasedate is null or
	language is null or
	stars is null or
	price is null;

-- ===================== language =====================

select distinct language
from data;

delete from data
where language <> 'English';

-- =====================================================

-- ======================= price =======================

-- Procurando por dados fora do padrão

select distinct price
from data
where price !~ '^(\d{1,3}(,\d{3})?\.\d{2})';

-- Convertendo o a coluna price para o tipo decinaml, e tratando ocorrências de 'Free'

select 
cast(case 
	when price !~ '(\d{1,3}(,\d{3})?\.\d{2})' then '0.00'
	else replace(price,',', '')
end as decimal(6, 2)) as price
from data;

-- =====================================================

-- ======================= stars =======================

-- Procurando por dados fora do padrão

select distinct stars
from data
where stars !~ '^([0-5]{1}(.\d{1})?) out of 5 stars((\d{1,3},)?\d{1,3}) rating[s]?$';

-- Retirando as ocorrências de ',' e separando as informações de stars e ratings, de tipo decimal e int respectivamente

select 
	cast(case
		when stars ~ '([0-5]{1}(.\d{1})?)' then split_part(stars, ' ', 1)
		else null
	end as decimal(2, 1)) as stars,
	cast(case
		when stars ~ '(stars\d{1,3}(,\d{3})*)' 
		then replace(ltrim(substring(stars from '(stars\d{1,3}(,\d{3})*)'), 'stars'), ',', '')
		else '0'
	end as integer) as ratings
from data;

-- =====================================================

-- =================== realeasedate ====================

-- Procurando por dados fora do padrão

select distinct realeasedate
from data
where realeasedate !~ '\d{2}-\d{2}-\d{2}';

-- Convertendo a coluna price para o tipo data

select to_date(realeasedate, 'DD-MM-YY')
from data;

-- =====================================================

-- ======================= time ========================

-- Procurando por dados fora do padrão

select distinct time 
from data
where time !~ '^\d{1,3}( mins?| hrs?| hrs? and \d{1,2} mins?)$';

-- Convertendo a coluna 'time' para a duração em minutos

select 
	cast(case
		when time ~ '^\d{1,3}( mins?| hrs?| hrs? and \d{1,2} mins?)$'
		then extract(epoch from replace(time, 'and ', '')::interval)/60
		else 0
	end as decimal(4, 0)) as duration
from data;
	
-- =====================================================

-- ====================== author =======================

-- Procurando por dados fora do padrão

select distinct author
from data
where author !~ '^Writtenby:[A-Za-z]+';

-- Procurando por campos com mais de um autor

select distinct author
from data
where author ~ '^Writtenby:[A-Za-z]+(,[A-Za-z]+)+';

-- Separando os diferentes autores em um campo, em índices de um array

with cleaned_author_select as (
	select trim(trailing ',' from replace(author, 'Writtenby:', '')) as cleaned_author
	from data),
	
arrays_author as (
select string_to_array(cleaned_author, ',') as arrays
from cleaned_author_select),

separated_columns_author as (
select
	case when arrays[1] is not null then arrays[1] else null end as author_1,
	case when arrays[2] is not null then arrays[2] else null end as author_2,
	case when arrays[3] is not null then arrays[3] else null end as author_3
from arrays_author)

select *
from separated_columns_author;

-- =====================================================

-- ===================== narrator ======================

-- Procurando por dados fora do padrão

select distinct narrator
from data
where narrator !~ '^Narratedby:[A-Za-z]+';

-- Separando os diferentes narradores em um campo, em índices de um array
-- Os tratamentos para esse campo serão os mesmos do campo 'author'

with cleaned_narrator_select as (
	select trim(trailing ',' from replace(narrator, 'Narratedby:', '')) as cleaned_narrator
	from data),
	
arrays_narrator as (
select string_to_array(cleaned_narrator, ',') as arrays
from cleaned_narrator_select),

separated_columns_narrator as (
select
	case when arrays[1] is not null then arrays[1] else null end as narrator_1,
	case when arrays[2] is not null then arrays[2] else null end as narrator_2,
	case when arrays[3] is not null then arrays[3] else null end as narrator_3
from arrays_narrator)

select * from separated_columns_narrator;

-- ====================================================
-- ====================== table =======================

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
		
	-- realeasedate
	
		to_date(realeasedate, 'DD-MM-YY') as realeasedate,
		
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
