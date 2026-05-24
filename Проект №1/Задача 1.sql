WITH 
anomaly_flats AS (
                   SELECT PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS wierd_total_area,
                          PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS wierd_rooms,
                          PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS wierd_balcony,
                          PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS wierd_ceiling_height_up,
                          PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS wierd_ceiling_height_down
                   FROM real_estate.flats 
),
filtered_flats AS (
                   SELECT id 
                   FROM real_estate.flats
                   WHERE total_area < (SELECT wierd_total_area FROM anomaly_flats)
                   AND (rooms < (SELECT wierd_rooms FROM anomaly_flats) OR rooms IS NULL)
                   AND (balcony < (SELECT wierd_balcony FROM anomaly_flats) OR balcony IS NULL)
                   AND ((ceiling_height < (SELECT wierd_ceiling_height_up FROM anomaly_flats)
                   AND ceiling_height > (SELECT wierd_ceiling_height_down FROM anomaly_flats)) OR ceiling_height IS NULL)
),
categories_count AS (
                     SELECT f.id,
                            CASE 
                     	         WHEN city_id = '6X8I'
                     	         THEN 'Санкт-Петербург'
                     	         WHEN city_id <> '6X8I' AND type_id = 'F8EM'
                     	         THEN 'ЛенОбл'
                     END AS region,
                            CASE
                            	 WHEN days_exposition >= 1 AND days_exposition <= 30
                            	 THEN '1 "До месяца"'
                            	 WHEN days_exposition <= 31 AND days_exposition <= 90
                            	 THEN '2 "До трех месяцев"'
                            	 WHEN days_exposition <= 91 AND days_exposition <= 180
                            	 THEN '3 "До полугода"'
                            	 WHEN days_exposition >= 181 
                            	 THEN '4 "Более полугода"'
                            	 WHEN days_exposition IS NULL
                            	 THEN '5 "Активные объявления"'
                     END AS exposition_category
                     FROM real_estate.flats AS f 
                     INNER JOIN filtered_flats AS ff USING(id)
                     LEFT JOIN real_estate.advertisement AS a USING(id)  
), 
one_m_cost_count AS (
                     SELECT id,
                            region,
                            exposition_category,
                            last_price/total_area AS one_m_cost
                     FROM real_estate.flats AS f 
                     INNER JOIN filtered_flats AS ff USING(id)
                     LEFT JOIN real_estate.advertisement AS a USING(id)
                     LEFT JOIN categories_count AS cc USING(id)
                     ORDER BY region DESC
)
SELECT omcc.region,
       omcc.exposition_category,
       COUNT(f.id) AS flats_count,
       AVG(omcc.one_m_cost) AS avg_m_cost,
       AVG(f.total_area) AS avg_total_area,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.rooms) AS median_rooms,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.balcony) AS median_balcony,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY f.floor) AS median_floor
FROM real_estate.flats AS f 
INNER JOIN filtered_flats AS ff USING(id)
LEFT JOIN real_estate.advertisement AS a USING(id)
LEFT JOIN one_m_cost_count AS omcc USING(id)
WHERE omcc.region IS NOT NULL
AND omcc.exposition_category IS NOT NULL
GROUP BY omcc.region,
         omcc.exposition_category
ORDER BY omcc.region DESC,
         omcc.exposition_category;