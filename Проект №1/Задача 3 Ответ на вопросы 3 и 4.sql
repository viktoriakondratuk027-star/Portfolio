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
)
SELECT c.city,
       f.city_id,
       COUNT(f.id) AS count_exposition,
       AVG(last_price/total_area) AS avg_one_m_price,
       AVG(total_area) AS avg_total_area,
       AVG(days_exposition) AS avg_days_exposition
FROM real_estate.city AS c 
RIGHT JOIN real_estate.flats AS f USING(city_id)
INNER JOIN filtered_flats AS ff USING(id)
LEFT JOIN real_estate.advertisement AS a USING(id)
WHERE id IN (SELECT * FROM filtered_flats)
AND city_id <> '6X8I'
GROUP BY DISTINCT c.city,
         f.city_id
ORDER BY count_exposition DESC
LIMIT 15;