-- Sub Queries are queries that generate output that will be used as input to the main query.
-- Queries that provide a single record, list, or even a table as output can be used as a subquery.


-- Returns single value
-- Print the highest imdb_rating's movie
select
	* 
from movies 
where imdb_rating = (select max(imdb_rating) from movies) ;

-- you can also write this query without subquery
-- The first find maxiam imdb_rating's movie and use that value in main query

-- max imdb_rating
select max(imdb_rating) from movies; -- 9.3

-- the highest imdb_rating movie
select
	* 
from movies 
where imdb_rating=9.3;


-- Returns a list of values
-- Print the highest and lowest imdb_rating's movie
select
	* 
from movies 
where imdb_rating IN ( (select max(imdb_rating) from movies),
					   (select min(imdb_rating) from movies)
					 );
   
   
-- Returns table
-- Print actors' name whose age is between 40 and 70
-- Actors table doesn't have age column, therefore calculate actors' age and then use that table in another table

-- calculate age column 
select
    name,
    year(curdate()) -birth_year as age
from actors ;

-- this query will fatch actors' name (b/w 40-70)
select
    *
from ( select
           name,
           year(curdate()) -birth_year as age
       from actors) as actor_age
where age between 40 and 70;


-- select all movies whose rating is greater than *any* of the marvel moveis rating
-- break down problem:- first find marvel studio's imdb_rating 
--                     then use this sub query in main query

-- Marvel studio's movies' imdb_rating (sub query)
select 
   imdb_rating
from movies
where studio ="marvel studios";

-- main query
select
  *
from movies
where imdb_rating > any(select 
                            imdb_rating
                        from movies
                        where studio ="marvel studios") ;
                        
-- select all movies whose rating is greater than *All* of the marvel moveis rating
select
  *
from movies
where imdb_rating > all(select 
                            imdb_rating
                        from movies
                        where studio ="marvel studios");

-- second way to write the same query
select
  *
from movies
where imdb_rating > all(select 
                            max(imdb_rating)
                        from movies
                        where studio ="marvel studios");
                        

-- Retrievel actors who acted in any of these movies
-- (101,,110, 121)
-- brek down problem : actor table has actor's name and actor_id columns
--                    movie_actor table has movie_id and actor_id columns
-- 1. first find actor_id from movies_actor table (for movie_id --> 101,,110, 121) 
-- 2. then use this sub-query in main query (with actors table)
--    because actors table has actors' name with thier actor_id
select
  *
from actors
where actor_id = any(select 
						 actor_id
                        from movie_actor
                        where movie_id IN (101,110, 121));
                        
-- we can write this query in another way
select
  *
from actors
where actor_id IN (select 
						 actor_id
                        from movie_actor
                        where movie_id IN (101,110, 121));
				
-- 1. Select all the movies with minimum and maximum release_year. Note that there
--    can be more than one movie in min and a max year hence output rows can be more than 2
select
   *
from movies
where release_year IN (
                        (select max(release_year) from movies),
					    (select MIN(release_year) from movies)
                      ) 
ORDER BY release_year desc ;

-- 2. Select all the rows from the movies table whose imdb_rating is higher than the average rating
select
   *
from movies
where imdb_rating > (select avg(imdb_rating) from movies);
                        
                        
-- Correlated sub-query
-- A subquery is called a co-related query when outer(main)
-- query depends on innner query.

-- selecte the actor id , actor name and ther total number of 
-- movies they performed in.
explain analyze 
select 
    a.actor_id, a.name, 
    count(movie_id) as movie_count
from actors a
inner join movie_actor ma
using (actor_id)
group by a.actor_id
order by movie_count desc; 

-- write same SQL qeury with Correlated sub-query
explain analyze 
SELECT 
    actor_id, name, -- select the actor_id and name columns from the actors table
    (SELECT COUNT(*) FROM movie_actor WHERE actor_id=a.actor_id) AS movie_count -- count the number of movies in which each actor has appeared, using the movie_actor table, and correlate the subquery to the outer query by using the actor_id column. The results are aliased as "movie_count".
FROM 
    actors a -- specify that the data is being selected from the actors table, which is aliased as "a".
ORDER BY 
    movie_count DESC ; -- order the results of the query in descending order of the movie_count column, using the "desc" keyword. 



-- 1. CTE (Comman Table Expression)
-- 2. CTE creates a temporary table within a query.
-- 3. WITH and AS clauses are used in combination to create CTE.
-- 4. One can create multiple CTEs inside a query

-- print movies that produces 500% profit and their rating was less than avg rating for all the movies

-- This query calculates the profit percentage for each movie in the financials table,
-- by subtracting the budget from the revenue and dividing the result by the budget.

with profit_pct as (
	select
		*,
		round((revenue - budget) * 100 / budget) as profit_pct
	from financials
),
-- This query selects all movies with an IMDb rating below the average rating of all movies.
movie_rating as (
	select 
		*
	from movies
	where imdb_rating < (
		select avg(imdb_rating)
		from movies
	)
)
-- This final select statement joins the profit_pct and movie_rating subqueries
-- and returns the title and profit percentage for each movie where the profit percentage is greater than or equal to 500.
-- The results are ordered by profit percentage in descending order.
select 
	title,
	profit_pct
from profit_pct pr
	join movie_rating mr on pr.movieId = mr.movie_id
where pr.profit_pct >= 500
order by pr.profit_pct desc;

-- Select all Hollywood movies released after the year 2000 that made more than 500 million $ profit or more
-- profit. Note that all Hollywood movies have millions as a unit hence you don't need to do the unit 
-- conversion. Also, you can write this query without CTE as well but you should try to write this using 
-- CTE only

with profit as (
	select
		*,
		round(revenue - budget,2)  as profit_mln
	from financials
),

movie_table as (
	select 
		*
	from movies
	where release_year>2000 and
          industry="Hollywood"	
)

select 
	title,
	profit_mln
from profit p
	join movie_table m on (p.movieId = m.movie_id)
where p.profit_mln >= 500
order by p.profit_mln desc;