-- 1 задача
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
categories AS (
	SELECT id,
		CASE
			WHEN city_id = '6X8I' THEN 'Санкт-Петербург'
			ELSE 'ЛенОбл'
			END AS city_category,
		CASE
			WHEN days_exposition BETWEEN 1 AND 30 THEN 'до месяца'
			WHEN days_exposition BETWEEN 31 AND 90 THEN 'до трёх месяцев'
			WHEN days_exposition BETWEEN 91 AND 180 THEN 'до полгода'
			WHEN days_exposition >= 181 THEN 'больше полугода'
			ELSE 'no_category'
		END AS exp_category,
		last_price / total_area AS cost_per_meter
	FROM real_estate.flats
	LEFT JOIN real_estate.advertisement USING(id)
	WHERE type_id = 'F8EM' AND id IN (SELECT * FROM filtered_id)
	)
-- Основной запрос
SELECT city_category,
	exp_category,
	AVG(cost_per_meter) AS avg_cost_per_meter,
	AVG(total_area) AS avg_total_area,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS median_rooms,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS median_balconies,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) AS median_floor,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floors_total) AS median_total_floor,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ceiling_height) AS median_ceiling,
	COUNT(id) AS total_adv,
	COUNT(id) / (SELECT COUNT(id) FROM categories WHERE city_category IS NOT NULL AND exp_category <> 'no_category')::real AS adv_share,
	SUM(is_apartment) / (SELECT COUNT(id) FROM categories WHERE city_category IS NOT NULL AND exp_category <> 'no_category')::REAL AS appart_share
FROM real_estate.flats
LEFT JOIN categories USING(id)
WHERE city_category IS NOT NULL AND exp_category <> 'no_category'
GROUP BY city_category, exp_category
ORDER BY adv_share DESC;
-- 2.1 задача (месяцы публикации)
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
SELECT EXTRACT(MONTH FROM first_day_exposition) AS first_month,
	COUNT(id) AS activity,
	AVG(last_price / total_area) AS avg_cost_per_meter,
	AVG(total_area) AS avg_total_area
FROM real_estate.flats
LEFT JOIN real_estate.advertisement USING(id)
WHERE id IN (SELECT * FROM filtered_id) AND type_id = 'F8EM'
GROUP BY first_month
ORDER BY activity DESC;
-- 2.2 задача (месяцы снятия)
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
SELECT EXTRACT(MONTH FROM (first_day_exposition::date + make_interval(days := days_exposition::int ))) AS last_month,
	COUNT(id) AS activity,
	AVG(last_price / total_area) AS avg_cost_per_meter,
	AVG(total_area) AS avg_total_area
FROM real_estate.flats
LEFT JOIN real_estate.advertisement USING(id)
WHERE id IN (SELECT * FROM filtered_id) AND days_exposition IS NOT NULL AND type_id = 'F8EM'
GROUP BY last_month
ORDER BY activity DESC;
-- 3 задача
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
sub_info AS (
	SELECT city,
	COUNT(id) AS flats_per_city
	FROM real_estate.flats
	LEFT JOIN real_estate.city USING(city_id)
	LEFT JOIN real_estate.advertisement USING(id)
	WHERE id IN (SELECT * FROM filtered_id) AND city_id <> '6X8I'
	GROUP BY city
	)
SELECT city,
	flats_per_city,
	COUNT(id) FILTER (WHERE days_exposition IS NOT NULL)/ flats_per_city::real AS perc_sold_per_city,
	AVG(last_price / total_area) AS avg_cost_per_meter,
	AVG(total_area) AS avg_total_area,
	AVG(days_exposition) AS avg_days_exposition
FROM real_estate.flats
LEFT JOIN real_estate.city USING(city_id)
LEFT JOIN real_estate.type USING(type_id)
LEFT JOIN sub_info USING(city)
LEFT JOIN real_estate.advertisement USING(id)
WHERE id IN (SELECT * FROM filtered_id) AND city_id <> '6X8I' AND flats_per_city >= 63
GROUP BY city, flats_per_city
ORDER BY perc_sold_per_city DESC
