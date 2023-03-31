select * from data;

-- Procurando valores nulos

select *
from data
where name is null or
	author is null or
	narrator is null or
	time is null or
	releasedate is null or
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

-- =================== releasedate ====================

-- Procurando por dados fora do padrão

select distinct releasedate
from data
where releasedate !~ '\d{2}-\d{2}-\d{2}';

-- Convertendo a coluna price para o tipo data

select to_date(releasedate, 'DD-MM-YY')
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
