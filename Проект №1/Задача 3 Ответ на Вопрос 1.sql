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
SELECT DISTINCT c.city,
       COUNT(id) AS exposition_number
FROM real_estate.city AS c 
RIGHT JOIN real_estate.flats AS f USING(city_id)
INNER JOIN filtered_flats AS ff USING(id)
WHERE city_id <> '6X8I'
GROUP BY DISTINCT c.city
ORDER BY exposition_number DESC
LIMIT 15;