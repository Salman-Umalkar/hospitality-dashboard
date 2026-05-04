create database group2;
use group2;
select *from dim_date;
select *from dim_hotels;
select *from dim_rooms;
select *from fact_aggregated_bookings;
select *from fact_bookings;


-- Transfroming data
ALTER TABLE dim_date ADD COLUMN wn INT;


UPDATE dim_date 
SET wn = CAST(SUBSTRING_INDEX(`week no`, ' ', -1) AS UNSIGNED);

ALTER TABLE dim_date ADD COLUMN converted_date DATE;
UPDATE dim_date
SET converted_date = STR_TO_DATE(`date`, '%d-%b-%y');


ALTER TABLE dim_date DROP COLUMN `date`;

ALTER TABLE dim_date CHANGE COLUMN converted_date `date` DATE;






-- 1)Total Revenue Generated , Total revenue Realized , Total Bookings , Total Checked Out, Total Cancelled Bookings
SELECT 
    CONCAT(ROUND(SUM(revenue_generated)/1000000, 2), ' M') AS `Total Revenue Generated`,
    CONCAT(ROUND(SUM(revenue_realized)/1000000, 2), ' M') AS `Total Revenue Realized`,
    CONCAT(ROUND(COUNT(booking_id)/1000, 2), ' K') AS `Total Bookings`,
    CONCAT(ROUND(COUNT(CASE WHEN booking_status = 'Checked Out' THEN booking_id END)/1000, 2), ' K') AS `Total Succesfull Bookings`,
    CONCAT(ROUND(COUNT(CASE WHEN booking_status = 'Cancelled' THEN booking_id END)/1000, 2), ' K') AS `Total Cancelled Booking`
FROM fact_bookings;


-- 2)Room Catgory Wise Total Capacity 
SELECT 
    room_category,
    CONCAT(ROUND(SUM(capacity)/1000, 2), ' K') AS `Total Capacity`
FROM fact_aggregated_bookings 
GROUP BY room_category;

-- 3)City Wise Total Revenue 

SELECT 
    city,
    CONCAT(ROUND(SUM(fb.revenue_realized)/1000000, 2), ' M') AS `Total Revenue Realized`,
    DENSE_RANK() OVER (ORDER BY SUM(fb.revenue_realized) DESC) AS `Revenue Rank`
FROM dim_hotels h
JOIN fact_bookings fb ON fb.property_id = h.property_id
GROUP BY city;

 
 
 -- 4)hotel wise Total Revenue 
 SELECT 
    h.property_name,
    CONCAT(ROUND(SUM(fb.revenue_realized)/1000000, 2), ' M') AS `Total Revenue Realized`,
    CONCAT(ROUND(COUNT(CASE WHEN fb.booking_status = 'Checked Out' THEN fb.booking_id END)/1000, 2), ' K') AS `Total Succesfull Bookings`,
    DENSE_RANK() OVER (ORDER BY SUM(fb.revenue_realized) DESC) AS `Revenue Rank`
FROM dim_hotels h
JOIN fact_bookings fb ON fb.property_id = h.property_id
GROUP BY h.property_name;

-- 5)week wise total Bookings and Total Revenue 

select d.wn,
CONCAT(ROUND(SUM(fb.revenue_realized)/1000000, 2), ' M') AS `Total Revenue Realized`,
CONCAT(ROUND(COUNT(CASE WHEN fb.booking_status = 'Checked Out' THEN fb.booking_id END)/1000, 2), ' K') AS `Total Succesfull Bookings`
from dim_date as d
join
fact_bookings fb
On
fb.check_in_date = d.date
group by d.wn;

-- 6)week over week Change % in Revenue

WITH weekly_data AS (
    SELECT 
        d.wn,
        SUM(fb.revenue_realized) AS total_revenue
    FROM dim_date d
    JOIN fact_bookings fb ON fb.check_in_date = d.date
    GROUP BY d.wn
)
SELECT 
    wn,
    CONCAT(ROUND(total_revenue / 1000000, 2), ' M') AS `Total Revenue Realized`,
    CONCAT(
        ROUND(
            (total_revenue - LAG(total_revenue) OVER (ORDER BY wn)) 
            / NULLIF(LAG(total_revenue) OVER (ORDER BY wn), 0) * 100, 
        2), 
    ' %') AS `WoW % Change in Revenue`
FROM weekly_data;


-- 7)Day Type wise Total Revenue & Total succesfull Bookings
select d.day_type,
CONCAT(ROUND(SUM(fb.revenue_realized)/1000000, 2), ' M') AS `Total Revenue Realized`,
CONCAT(ROUND(COUNT(CASE WHEN fb.booking_status = 'Checked Out' THEN fb.booking_id END)/1000, 2), ' K') AS `Total Succesfull Bookings`
from dim_date d
join
fact_bookings fb
on
fb.check_in_date=d.date
group by d.day_type;


-- 8)booking platform wise Total Revenue
SELECT 
    booking_platform,
    CONCAT(ROUND(SUM(revenue_realized)/1000000, 2), ' M') AS `Total Revenue`
FROM fact_bookings
GROUP BY booking_platform
ORDER BY SUM(revenue_realized) DESC;



