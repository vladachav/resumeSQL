/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Косачев В.А.
 * Дата: 28.06.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT
	COUNT(id) AS users_total,
	SUM(payer) AS payers_total,
	AVG(payer) AS payers_prop
FROM fantasy.users;
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT
	race,
	SUM(payer) AS payers_per_race,
	COUNT(id) AS users_per_race,
	SUM(payer)/COUNT(id)::real AS payers_prop_race
FROM fantasy.users
LEFT JOIN fantasy.race USING(race_id)
GROUP BY race
ORDER BY payers_prop_race;
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT
	COUNT(DISTINCT transaction_id) AS trans_count_total,
	SUM(amount) AS trans_sum_total,
	MIN(amount) AS trans_min,
	MAX(amount) AS trans_max,
	AVG(amount) AS trans_avg,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS trans_med,
	STDDEV(amount) AS trans_stand_dev
FROM fantasy.events;
-- 2.2: Аномальные нулевые покупки:
SELECT
	COUNT(transaction_id) AS count_pay,
	COUNT(transaction_id) FILTER (WHERE amount = 0) AS count_null_pay,
	COUNT(transaction_id) FILTER (WHERE amount = 0) / COUNT(*)::FLOAT AS percent_pay
FROM fantasy.events;
-- 2.3: Популярные эпические предметы:
WITH total_stat AS (
	SELECT DISTINCT item_code,
	COUNT(transaction_id) OVER() AS total_buy
	FROM fantasy.events
	WHERE amount > 0),
	share_stat AS (
	SELECT item_code,
	COUNT(transaction_id) AS item_buy,
	COUNT(id) AS item_buyers
	FROM fantasy.events
	WHERE amount > 0
	GROUP BY item_code)
SELECT
	game_items,
	item_buy,
	item_buy/total_buy::real AS share_buy,
	item_buyers/(SELECT COUNT(id) AS total_buyers FROM fantasy.events WHERE amount <> 0)::real AS share_buyers
FROM total_stat
JOIN share_stat USING(item_code)
JOIN fantasy.items USING(item_code)
ORDER BY share_buyers DESC;
-- Часть 2. Решение ad hoc-задачbи
-- Задача: Зависимость активности игроков от расы персонажа:
WITH gamers_stat AS (
	SELECT race_id,
	COUNT(DISTINCT id) AS race_gamers
	FROM fantasy.users
	GROUP BY race_id
	),
buyers_stat AS (
	SELECT race_id,
	COUNT(DISTINCT id) FILTER (WHERE amount <> 0 AND payer=1) AS race_payers,
	COUNT(DISTINCT id) FILTER (WHERE payer = 1) AS race_buyers
	FROM fantasy.users
	LEFT JOIN fantasy.events USING(id)
	GROUP BY race_id),
orders_stat AS (
	SELECT race_id,
	COUNT(transaction_id) AS total_orders,
	SUM(amount) AS total_amount
	FROM fantasy.users
	LEFT JOIN fantasy.events USING(id)
	WHERE amount > 0
	GROUP BY race_id)
SELECT
    race,
    race_gamers,
    race_buyers,
    race_buyers::real/race_gamers AS buyers_gamers_share,
    race_payers::real/race_buyers AS payer_buyers_share,
    total_orders::real/race_buyers AS orders_per_buyer,
    total_amount::real/total_orders AS total_amount_per_buyer,
    total_amount::real/race_buyers AS avg_amount_per_buyer
FROM gamers_stat JOIN orders_stat USING(race_id) JOIN buyers_stat USING(race_id)
JOIN fantasy.race USING(race_id)

ORDER BY avg_amount_per_buyer DESC
