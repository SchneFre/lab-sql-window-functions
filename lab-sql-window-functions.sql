USE sakila;
-- Rank films by their length and create an output table that includes the title, length, and rank columns only. 
-- Filter out any rows with null or zero values in the length column.
SELECT 
	title,
    length,
    RANK() OVER (ORDER BY length DESC) as length_rank
FROM 
	film
WHERE length is not null and length > 0;

-- Rank films by length within the rating category and create an output table that 
-- includes the title, length, rating and rank columns only. 
-- Filter out any rows with null or zero values in the length column.

SELECT 
	f.title,
    f.length,
    f.rating,
    -- fc.category_id,
    RANK() OVER(PARTITION BY fc.category_id ORDER BY length DESC) as length_rank
FROM 
	film as f
JOIN film_category as fc
ON fc.film_id = f.film_id
WHERE length is not null and length > 0
ORDER BY RANK() OVER(PARTITION BY fc.category_id ORDER BY length DESC);

-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, 
-- as well as the total number of films in which they have acted.
-- Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH film_count_of_actors AS(
	SELECT 
		a.actor_id,
		a.first_name,
		a.last_name,
		COUNT(film_id) as film_count
	FROM 
		actor as a
	JOIN film_actor as fa
	ON a.actor_id = fa.actor_id
	GROUP BY a.actor_id
	ORDER BY film_count DESC
),
actors_of_films AS( 
	SELECT
		f.*,
		fa.actor_id,
        fca.first_name,
        fca.last_name,
		fca.film_count
	FROM 
		film as f
	JOIN 
		film_actor as fa
	ON f.film_id = fa.film_id
	JOIN film_count_of_actors as fca
	ON fca.actor_id = fa.actor_id
),
ranked_actors as(
SELECT 
	*,
    DENSE_RANK() OVER(PARTITION BY title ORDER BY film_count DESC) as actor_rank
FROM actors_of_films
)
SELECT 
	title,
    first_name as actor_first_name,
    last_name as actor_last_name,
    film_count as actor_film_count
FROM ranked_actors
WHERE actor_rank = 1;

-- Challenge 2
-- Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.

SELECT 
	COUNT(DISTINCT(r.customer_id)) as unique_customers,
    DATE_FORMAT(rental_date, '%Y-%m') AS year_month_rental
FROM rental as r
GROUP BY year_month_rental
ORDER BY year_month_rental;

--  Retrieve the number of active users in the previous month.
WITH monthly_users AS (
    SELECT 
        DATE_FORMAT(rental_date, '%Y-%m') AS year_month_rental,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT 
    year_month_rental,
    unique_customers,
    LAG(unique_customers) OVER (ORDER BY year_month_rental) AS prev_month_customers
FROM monthly_users
ORDER BY year_month_rental;

-- Calculate the percentage change in the number of active customers between the current and previous month.

WITH monthly_users AS (
    SELECT 
        DATE_FORMAT(rental_date, '%Y-%m') AS year_month_rental,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT 
    year_month_rental,
    unique_customers,
    (unique_customers - LAG(unique_customers) OVER (ORDER BY year_month_rental) ) / LAG(unique_customers) OVER (ORDER BY year_month_rental) AS percentage_delta
FROM monthly_users
ORDER BY year_month_rental;


-- Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.

WITH rentals_by_month AS (
    SELECT 
        customer_id,
        DATE_FORMAT(rental_date, '%Y-%m') AS ym
    FROM rental
    GROUP BY customer_id, DATE_FORMAT(rental_date, '%Y-%m')
),
retention_pairs AS (
    SELECT 
        curr.ym AS current_month,
        COUNT(*) AS retained_customers
    FROM rentals_by_month curr
    JOIN rentals_by_month prev
        ON curr.customer_id = prev.customer_id
        AND prev.ym = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(curr.ym, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
    GROUP BY curr.ym
)
SELECT 
    current_month,
    retained_customers
FROM retention_pairs
ORDER BY current_month;
