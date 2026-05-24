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
exstract_month_pub AS (
                       SELECT a.id, 
                              a.last_price/f.total_area AS one_m_cost,
                              f.total_area AS total_area,
                              EXTRACT(MONTH FROM a.first_day_exposition::timestamp) AS pub_exposition_month 
                       FROM real_estate.advertisement AS a 
                       INNER JOIN filtered_flats AS ff USING(id)
                       LEFT JOIN real_estate.flats AS f USING(id)
                       WHERE a.first_day_exposition BETWEEN '2015-01-01' AND '2018-12-01'
                         AND f.type_id = 'F8EM' 
                       ORDER BY a.first_day_exposition DESC
),
count_pub AS (
-- Запрос для публикации объявлений;
              SELECT pub_exposition_month,
                     COUNT(id) AS pub_number_of_flats,
                     ROUND((AVG(one_m_cost)::NUMERIC),1) AS pub_avg_one_m_cost,
                     ROUND((AVG(total_area)::NUMERIC),1) AS pub_avg_total_area
              FROM exstract_month_pub
              GROUP BY pub_exposition_month
              ORDER BY pub_number_of_flats DESC
),
exstract_month_sell AS (
                   SELECT a.id, 
                          a.last_price/f.total_area AS one_m_cost,
                          f.total_area AS total_area,
                          EXTRACT(MONTH FROM (a.first_day_exposition + INTERVAL '1 day' * days_exposition)) AS sell_exposition_month 
                   FROM real_estate.advertisement AS a 
                   INNER JOIN filtered_flats AS ff USING(id)
                   LEFT JOIN real_estate.flats AS f USING(id)
                   WHERE a.first_day_exposition BETWEEN '2015-01-01' AND '2018-12-01'
                         AND a.days_exposition IS NOT NULL
                         AND f.type_id = 'F8EM' 
                   ORDER BY a.first_day_exposition DESC
), 
-- Запрос для снятия объявлений;
count_sell AS (
             SELECT sell_exposition_month,
                    COUNT(id) AS sell_number_of_flats,
                    ROUND((AVG(one_m_cost)::NUMERIC),1) AS sell_avg_one_m_cost,
                    ROUND((AVG(total_area)::NUMERIC),1) AS sell_avg_total_area
             FROM exstract_month_sell
             GROUP BY sell_exposition_month 
             ORDER BY sell_number_of_flats DESC
)
SELECT p.pub_exposition_month,
       s.sell_exposition_month, 
       p.pub_number_of_flats,
       s.sell_number_of_flats,
       p.pub_avg_one_m_cost,
       s.sell_avg_one_m_cost, 
       p.pub_avg_total_area,
       s.sell_avg_total_area 
FROM count_pub AS p
FULL JOIN count_sell AS s ON p.pub_exposition_month = s.sell_exposition_month;

             
             
             
             
             
             
             