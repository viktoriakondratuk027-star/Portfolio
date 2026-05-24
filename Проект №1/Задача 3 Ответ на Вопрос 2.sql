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
flats_count AS (
                SELECT DISTINCT c.city AS city,
                       f.city_id AS city_id,
                       COUNT(days_exposition) AS sold_flats,
                       COUNT(f.id) AS all_flats
                FROM real_estate.advertisement AS a
                INNER JOIN filtered_flats AS ff USING(id)
                LEFT JOIN real_estate.flats AS f USING(id)
                LEFT JOIN real_estate.city AS c USING(city_id)
                WHERE city_id <> '6X8I'
                GROUP BY DISTINCT c.city,
                         f.city_id
                ORDER BY sold_flats DESC
                LIMIT 15
)
SELECT city,
       city_id,
       sold_flats,
       all_flats,
       ROUND((sold_flats::NUMERIC/all_flats::NUMERIC),2) AS part_sold_flats
FROM flats_count
ORDER BY part_sold_flats DESC;