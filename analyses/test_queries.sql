--Check the current user of the database
SELECT current_user;

--Check the current database
SELECT current_database();

--Check the test_model table in the public_pipedrive_analytics schema
SELECT * 
FROM  public_pipedrive_analytics.test_model;

--Quick proof check to see if all the tables are created 
SELECT table_name
FROM information_schema.tables
WHERE table_schema='public';

----------------------------------------------------------------------------------------------------------------------------------------
-- activity table analysis

SELECT * 
FROM activity
ORDER BY activity_id DESC;
--4579 rows found

SELECT activity_id
    , COUNT(*) AS count
FROM activity
GROUP BY 1
HAVING COUNT(*) > 1;
-- 11 duplicate ID's found

SELECT * 
FROM activity
WHERE activity_id IN (521731, 332746, 283914, 370773, 818588, 855539, 206894, 835226, 488221, 283308, 500358)
ORDER BY activity_id;


-- Found duplicate activity_id's, there are 11 activity_id's that are duplicated 

SELECT activity_id
    , COUNT(*) AS count
FROM activity
WHERE TRUE
    AND done = 'true'
GROUP BY 1
HAVING COUNT(*) > 1;

-- dupliacte activity ids either have one record as done = 'true' and the other as done = 'false' or both records as done = 'false'
-- indicating that when done = 'true' is used no duplicates are found

SELECT COUNT(DISTINCT activity_id) AS unique_activity_id_count
FROM activity;
-- Total unique count of activity_id : 4568    

SELECT COUNT(activity_id) AS unique_activity_id_count
FROM activity
WHERE TRUE
    AND done = 'true';
-- Total activites with Done as True : 2290


SELECT COUNT(DISTINCT activity_id) AS unique_activity_id_count
FROM activity
WHERE TRUE
    AND activity_id NOT IN (
        SELECT activity_id
        FROM activity
        GROUP BY 1
        HAVING COUNT(activity_id) > 1
    )
-- Unique activities 4557 without duplicates

SELECT *
FROM activity
WHERE TRUE
    AND activity_id IN (
        SELECT activity_id
        FROM activity
        GROUP BY 1
        HAVING COUNT(*) > 1
    )
    AND assigned_to_user IN (
        SELECT DISTINCT id
        FROM users
    )
ORDER BY activity_id;

-- Same activity_id's assigned to different user_id's with different deal_id's
-- also same activity_id's with different type's and different due_to's (timestamps)
-- this could be due to data entry errors, system glitches, or intentional duplication for tracking purposes

SELECT a.*
    , at.name
FROM activity a
LEFT JOIN activity_types at
    ON at.type = a.type
ORDER BY assigned_to_user, activity_id, due_to;

-- Noticed when i grouped by assigned_to_user, activity_id, due_to the rows had activity type in no particular order that was being followed 

SELECT DISTINCT(at.name) AS activity_name
    , COUNT(*) AS activity_count
FROM activity
LEFT JOIN activity_types at
    ON at.type = activity.type
GROUP BY 1
ORDER BY activity_count DESC;

 
-- After Close Call (type : after_close_call) has the highest activity count & Sales Call 2 (type : sc_2) has the lowest activity count
-- while Sales Call 1 (type : meeting) has the second highest activity count and Follow Up Call (type : follow_up_call) has the second lowest activity count

SELECT DISTINCT(at.name) AS activity_name
    , COUNT(*) AS activity_count
FROM activity
LEFT JOIN activity_types at
    ON at.type = activity.type
WHERE TRUE
    AND done = 'true'
GROUP BY 1
ORDER BY activity_count DESC;

-- After Close Call (type : after_close_call) has the highest completed activity count & Sales Call 2 (type : sc_2) has the lowest completed activity count
-- while Sales Call 1 (type : meeting) has the second highest completed activity count and Follow Up Call (type : follow_up_call) has the second lowest completed activity count


SELECT assigned_to_user AS user_id
    , COUNT(activity_id) AS activity_count
FROM activity
GROUP BY 1
HAVING  COUNT(activity_id) > 1
ORDER BY activity_count DESC;


SELECT at.*, u.name
FROM activity at
LEFT JOIN users u
    ON at.assigned_to_user = u.id
WHERE TRUE
    AND assigned_to_user IN (1200, 813)
ORDER BY assigned_to_user, due_to, activity_id;

-- Daniel Clark (user_id: 1200) has the highest activity count of 11 activities assigned to him
-- followed by 	Anthony Anderson (user_id: 813) with 9 activities assigned to him


SELECT activity_id
    , assigned_to_user
    , due_to
FROM activity
WHERE TRUE
GROUP BY 1, 2, 3
HAVING COUNT(*) > 1;

-- no duplicate activity_id + assigned_to_user + due_to combinations found
-- we will use this combination to generate a surrogate key for activity table in the data warehouse


-- Check nulls in key columns
SELECT COUNT(*) FILTER (WHERE activity_id IS NULL) AS missing_activity_id
    , COUNT(*) FILTER (WHERE deal_id IS NULL) AS missing_deal_id
    , COUNT(*) FILTER (WHERE assigned_to_user IS NULL) AS missing_user_id
    , COUNT(*) FILTER (WHERE type IS NULL) AS missing_activity_type
    , COUNT(*) FILTER (WHERE due_to IS NULL) AS missing_due_to
FROM activity;
-- no null records

----------------------------------------------------------------------------------------------------------------------------------------
-- activity_type table analysis

SELECT * 
FROM activity_types;

-- activity + activity_type table join to find out which id's in activity_type are present in the activity table

SELECT at.id AS activity_type_id
    , at.name AS activity_type_name
    , a.type AS activity_type_short
    , at.active AS activity_type_active_status
    , COUNT(activity_id) AS activity_id_count  
FROM activity a
LEFT JOIN activity_types at
    ON at.type = a.type
WHERE TRUE
    AND at.active IN ('Yes', 'No')
GROUP BY 1, 2, 3, 4
ORDER BY at.id;

-- All active activity types are present in the activity table
--'Follow Up Call' is in an inactive state, and we do notice some activity_id's with this type in the activity table -
-- it could be that the activity type was changed to inactive after some activities of that type were already logged

----------------------------------------------------------------------------------------------------------------------------------------
-- users table analysis

SELECT * 
FROM users;

-- 1787 users found

SELECT *
FROM users
WHERE TRUE
    AND id IN (
        SELECT id
        FROM users
        GROUP BY 1
        HAVING COUNT(*) > 1
    )
ORDER BY id;
-- no duplicate user id's found

-- activity + user table join to find out which users in the activity table are not present in the user table

SELECT DISTINCT(a.assigned_to_user) AS activity_user_id
    , u.id AS user_id 
FROM activity a
LEFT JOIN users u 
    ON a.assigned_to_user = u.id
WHERE TRUE
    AND u.id IS NULL
ORDER BY user_id;

-- no users found in activity table that are not present in the user table
-- This indicates that all users assigned to activities are valid users in the system


SELECT COUNT(*) FILTER (WHERE name IS NULL OR email IS NULL)
FROM users;
-- there are no missing identities in the users table

-- check for non-key duplicates in name & email columns

SELECT name
    , COUNT(*) AS name_count
FROM users
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY name_count DESC;

SELECT email
    , COUNT(*) AS name_count
FROM users
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY name_count DESC;

SELECT *
FROM users
WHERE name in ('Robin Willis', 'Jennifer Wilkerson', 'Benjamin Garcia', 'Regina Davis', 'Paul Williams')
ORDER BY name;

SELECT *
FROM users
WHERE email in ('david39@example.net', 'tbarrera@example.com', 'dustin04@example.net', 'fbrown@example.com');

-- there are 21 duplicate names  & 4 dupliacte emails found in the users table with different id's and emails


-- Check nulls in key columns
SELECT COUNT(*) FILTER (WHERE id IS NULL) AS missing_id
    , COUNT(*) FILTER (WHERE name IS NULL) AS missing_name
    , COUNT(*) FILTER (WHERE email IS NULL) AS missing_email
    , COUNT(*) FILTER (WHERE modified IS NULL) AS missing_modified
FROM users;
-- no null records

----------------------------------------------------------------------------------------------------------------------------------------
-- fields + stages + deal_changes table analysis

SELECT * 
FROM fields;
-- there are 4 unique field keys
-- name in field table corresponds to the changed_field_key in deal_changes table
-- stage in field table corresponds to the stages table
-- lost_reason in field table does not have a corresponding picklist table

SELECT * 
FROM stages;
-- there are 9 unique stages


SELECT *
FROM deal_changes
ORDER BY deal_id, change_time;

SELECT DISTINCT(changed_field_key) AS field_key
FROM deal_changes;

SELECT deal_id
    , COUNT(*) AS deal_change_count
FROM deal_changes
GROUP BY deal_id
ORDER BY deal_change_count DESC;

-- confirms one deal has multiple deal_changes.


SELECT deal_id
    , change_time
    , COUNT(*) AS count
FROM deal_changes
GROUP BY 1, 2
HAVING COUNT(*) > 1;


SELECT COUNT(*) FILTER (WHERE deal_id IS NULL) AS missing_deal_id
    , COUNT(*) FILTER (WHERE change_time IS NULL) AS missing_change_time
    , COUNT(*) FILTER (WHERE changed_field_key IS NULL) AS missing_field_key
    , COUNT(*) FILTER (WHERE new_value IS NULL) AS missing_new_value
FROM deal_changes;

-- no null values

-- changed_field_key validity
SELECT DISTINCT changed_field_key
FROM deal_changes
WHERE changed_field_key NOT IN (
  SELECT field_key FROM fields
);

-- all changed_field_key values are valid as per fields table

SELECT * 
FROM deal_changes
WHERE TRUE
    AND changed_field_key = 'user_id'
    AND new_value NOT IN (
        SELECT CAST(id AS TEXT)
        FROM users
    );

-- null indicates all the users created in deal_changes table are present in users table

-- To ensure stage_id only moves forward and does not go backward for any deal_id
WITH ordered AS (
  SELECT deal_id
    , change_time
    , CAST(new_value AS INT) AS stage_id
    , LAG(CAST(new_value AS INT)) OVER (PARTITION BY deal_id ORDER BY change_time) AS prev_stage
  FROM deal_changes
  WHERE changed_field_key = 'stage_id'
)
SELECT deal_id
    , change_time
    , prev_stage
    , stage_id
FROM ordered
WHERE prev_stage IS NOT NULL
  AND stage_id < prev_stage
ORDER BY deal_id, change_time;

SELECT *
FROM deal_changes
WHERE TRUE
    AND deal_id IN (399956)
--  AND changed_field_key = 'stage_id'
ORDER BY change_time;

-- looks like a deal is re-opened with a new user_id and the stage_id goes back to an earlier stage
--  for the above example, the deal changes are not strictly in chronological order based on change_time

SELECT *
FROM deal_changes
WHERE TRUE
    AND deal_id IN (556338, 851850, 955417)
--  AND changed_field_key = 'stage_id'
ORDER BY deal_id, change_time;

-- similar case as above and stage_id goes back to an earlier stage

SELECT *
FROM deal_changes
WHERE TRUE
    AND deal_id IN (851850)
--  AND changed_field_key = 'stage_id'
ORDER BY deal_id, change_time;

-- similar to example 399956 where deal is re-opened with a new user_id and the stage_id goes back to an earlier stage

SELECT *
FROM deal_changes
WHERE TRUE
    AND deal_id IN (955417)
--  AND changed_field_key = 'stage_id'
ORDER BY deal_id, change_time, changed_field_key, new_value

-- this example has duplicate stage_id's when ordered by change_time

WITH lost_reason_unnested AS (
SELECT CAST(v.value->>'id' AS INT) AS lost_reason_id   
    , v.value->>'label' AS lost_reason_name           
FROM fields
JOIN LATERAL jsonb_array_elements(field_value_options) AS v(value) ON TRUE -- Postgres function to expand JSON array into rows
WHERE field_key = 'lost_reason'
)
SELECT DISTINCT new_value
FROM deal_changes
WHERE TRUE 
    AND changed_field_key = 'lost_reason'
    AND new_value NOT IN (
        SELECT CAST(lost_reason_id AS TEXT)
        FROM lost_reason_unnested
    );
-- null value indicates all lost_reason_id's in deal_changes table are present in fields table


WITH stages_unnested AS (
SELECT CAST(v.value->>'id' AS INT) AS stage_id   
    , v.value->>'label' AS stage_name           
FROM fields
JOIN LATERAL jsonb_array_elements(field_value_options) AS v(value) ON TRUE -- Postgres function to expand JSON array into rows
WHERE field_key = 'stage_id'
)
SELECT DISTINCT new_value
FROM deal_changes
WHERE TRUE 
    AND changed_field_key = 'stage_id'
    AND new_value NOT IN (
        SELECT CAST(stage_id AS TEXT)
        FROM stages_unnested
    );
-- null value indicates all stage_id's in deal_changes table are present in fields table


SELECT * 
FROM deal_changes
ORDER BY deal_id, change_time;

-- 15406 rows returned
-- The deal_changes table has multiple rows for the same deal_id, indicating that a single deal can undergo multiple changes over time

SELECT * 
FROM deal_changes 
WHERE deal_id IN (SELECT DISTINCT deal_id FROM deal_changes LIMIT 4)
ORDER BY deal_id, change_time;
/*
1. the field table has unique rows (aka field_keys) which are used in the deals table. The field_value_option column is a json array.
2. The field_value_option has JSON value only for two field_keys - stage_id (name: Stage) & lost_reason (name: Lost reason); while the other 
   field_keys - add_time (name: Deal created) & user_id(name: Owner) have NULL values
3. Upon analyzing the field_value_option json column further, we notice that all the key-value pairs for field_key named 'stage_id (Stage)' 
   are present on a picklist table named 'stages' as key represented as 'stage_id' & value represented as 'stage_name'
4. And for field_key named 'lost_reason (Lost reason), the field_value_option has json values that are not present in any picklist table; 
   a new picklist table named 'lost_reasons' can be created to store these key-value pairs
5. The changed_field_key column in the deal_changes table has values that correspond to the field_key values in the fields table
6. The new_value column in the deal_changes table contains the updated values for the respective changed_field_key
7. The deal_changes table has field changes in the following order -> add_time -> user_id -> stage_id (with stage id 1 - 9 in order) -> 
   and a lost_reason id
   -- this indicates that when a new deal is created, the add_time field is populated first, followed by the user_id field, then the 
   stage_id field
   -- as the deal progresses through different stages, and finally if the deal is lost, the lost_reason field is populated
   -- this is not true for all deals though, as some deals have user_id changes after lost_reason changes
   -- and in some cases the stage_id changes are not in order
8. A deal can have stage_id skipped while progressing through different stages
   -- example, deal_id 100086 has stage_id 1, 3, 4, 6, 7 ; stage_id 2, 5, 8 & 9 is skipped
9. The changed_time column in the deal_changes table indicates the timestamp when the change was made
10. When a new deal is defined on the deal_changes table, the changed_field_key column has values that are representative of the 
   field_keys column in the fields table and the new_column value on the deal_changes table has values that are representative of 
   the field_value_option
   -- If a deal requires an update on the 'add_time' field, the fields table has a row with field_key = 'add_time' with
   a field_value_option of NULL; and the deal_changes table will have a row with changed_field_key = 'add_time' with a date-time  
   value inputted in new_value
   --If a deal requires an update on the 'user_id' field, the fields table has a row with field_key = 'user_id' with
   a field_value_option of NULL; and the deal_changes table will have a row with changed_field_key = 'user_id' with a new integer 
   user id is inputted in new_value
   -- If a deal requires an update on the 'stage_id' field, the fields table has a row with field_key = 'stage_id' with
   a field_value_option of json array with key-value pairs of stage_id & stage_name from the stages table; and the deal_changes 
   table will have a row with changed_field_key = 'stage_id' with a new integer stage id is inputted in new_value
   -- If a deal requires an update on the 'lost_reason' field, once a new pick-list table (lets call it lost_reasons 
   with columns lost_reason_id & lost_reason_name) is created, the fields table has a row with field_key = 'lost_reason' with a 
   field_value_option of json array with key-value pairs of lost_reason_id & lost_reason_name; and the deal_changes table will have 
   a row with changed_field_key = 'lost_reason' with a new integer lost_reason id is inputted in new_value
*/


-- Check nulls in key columns
SELECT COUNT(*) FILTER (WHERE deal_id IS NULL) AS missing_deal_id
    , COUNT(*) FILTER (WHERE change_time IS NULL) AS missing_change_time
    , COUNT(*) FILTER (WHERE changed_field_key IS NULL) AS missing_changed_field_key
    , COUNT(*) FILTER (WHERE new_value IS NULL) AS missing_new_value
FROM deal_changes;
-- no null records


----------------------------------------------------------------------------------------------------------------------------------------
-- Cross table analysis

SELECT
    deal_id,
    COUNT(*) AS activity_count
FROM activity
GROUP BY deal_id
ORDER BY activity_count DESC;
-- activity tables references 4,572 unique deal_ids.

SELECT
    deal_id,
    COUNT(*) AS activity_count
FROM activity
GROUP BY deal_id
HAVING COUNT(*) > 1
ORDER BY activity_count DESC;
-- 7 deal_id has multiple activities (with 2 activities each)

SELECT * 
FROM activity
WHERE TRUE
    AND deal_id IN (
        SELECT deal_id
        FROM deal_changes
        WHERE TRUE
    )
ORDER BY activity_id, deal_id;
-- only 8 deals in common between activity and deal_changes table

SELECT *
FROM activity
WHERE deal_id IN (514881, 960413, 864101, 628425, 478434, 793245, 692622)
ORDER BY deal_id, activity_id;

SELECT
    COUNT(DISTINCT deal_id)
FROM deal_changes;
-- deal changes reference 1995 unique deal_ids

-- In summary :
-- 4564 activities logged on deals that were never initiated in deal_changes table
-- 1987 deals were created but activities weren't logged against them


SELECT MIN(due_to) AS earliest_due
    , MAX(due_to) AS latest_due
FROM activity;

-- earliest_due : 2024-01-01 02:37:06
-- latest_due : 2024-09-13 23:15:20


SELECT LOWER(a.type)
    , at.name AS activity_type
    , COUNT(DISTINCT activity_id) AS activity_count
FROM activity a
JOIN activity_types at
    ON a.type = at.type
WHERE TRUE
    AND LOWER(a.type) IN ('meeting', 'sc_2')
    AND done = 'true'
    AND active = 'Yes'
GROUP BY 1,2
-- 	Activity Count : Sales Call 1: 568 & Sales Call 2 : 560 

SELECT activity_id
    , deal_id
    , COUNT(*) AS activity_deal_count
FROM activity
GROUP BY 1, 2
HAVING COUNT(*) > 1
-- no duplicate activity_id + deal_id combinations found


SELECT deal_id
    , change_time
    , changed_field_key
    , new_value
    , COUNT(*) AS deal_change_count
FROM deal_changes
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) > 1
-- no duplicate deal_id + change_time + changed_field_key + new_value combinations found

SELECT MIN(change_time) AS earliest_change
    , MAX(change_time) AS latest_change
FROM deal_changes;

-- earliest_change : 2024-01-01 01:19:09
-- latest_change : 2025-03-11 17:17:07

-- this indicates that activities have been logged for deals only for short period of time compared to the deal changes

-- QA CHECK FOR activites count in activities
SELECT at.name AS activity_type
    , COUNT(DISTINCT activity_id) AS activity_count
FROM activity a
JOIN activity_types at
    ON a.type = at.type
WHERE TRUE
    AND LOWER(a.type) IN ('meeting', 'sc_2')
    AND done = 'true'
    AND active = 'Yes'
    AND DATE_TRUNC('month', due_to)::DATE = '2024-09-01'::DATE
GROUP BY 1;


-- QA CHECK FOR Deal count in Deal Changes
WITH raw_filtered AS (
    SELECT
       MD5(
            COALESCE(deal_id::text,'') ||
            COALESCE(change_time::text,'') ||
            COALESCE(changed_field_key,'')
        ) AS deal_change_sk
        , deal_id
        , change_time
        , changed_field_key
        , new_value
        , s.stage_name
    FROM deal_changes dc
    JOIN stages s
        ON dc.new_value::int = s.stage_id 
    WHERE TRUE
        AND deal_id IS NOT NULL
        AND LOWER(changed_field_key) = 'stage_id'
        AND DATE_TRUNC('month', change_time)::DATE = '2024-05-01'::DATE
)
SELECT stage_name
    , COUNT( dc.deal_change_sk) AS deal_count
FROM raw_filtered dc
GROUP BY 1;
----------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS public.funnel_steps;
DROP TABLE IF EXISTS public.test_deal_activity_stage;
DROP TABLE IF EXISTS public.int_activities;
DROP TABLE IF EXISTS public.int_months_funnel_grid;
----------------------------------------------------------------------------------------------------------------------------------------
-- Staging Tables Analysis

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name ILIKE 'stg_users';

SELECT *
FROM pipedrive_analytics.stg_users
ORDER BY user_id DESC;

SELECT *
FROM pipedrive_analytics.stg_activity_types;

SELECT *
FROM pipedrive_analytics.stg_fields;

SELECT *
FROM pipedrive_analytics.stg_stages;

SELECT *
FROM pipedrive_analytics.stg_lost_reasons;

SELECT *
FROM pipedrive_analytics.stg_deal_changes;

SELECT COUNT(DISTINCT deal_change_sk) 
FROM pipedrive_analytics.stg_deal_changes
WHERE deal_updated_field_key = 'stage_id'
--8906


SELECT *
FROM pipedrive_analytics.stg_activities;



SELECT COUNT(activity_event_sk)
FROM pipedrive_analytics.stg_activities a
LEFT JOIN pipedrive_analytics.stg_activity_types at
  ON a.activity_type_short = at.activity_type_short
WHERE TRUE
  AND a.is_activity_done_status = 'true'
  AND at.is_activity_type_active = 'Yes'
  AND LOWER(a.activity_type_short) IN ('meeting', 'sc_2');
-- 1128 records

WITH raw_counts AS (
    -- Counts from the RAW Source Schema (e.g., public schema)
    SELECT 'activity' AS table_name, COUNT(*) AS raw_rows FROM activity
    UNION ALL
    SELECT 'activity_types', COUNT(*) FROM activity_types
    UNION ALL
    SELECT 'deal_changes', COUNT(*) FROM deal_changes
    UNION ALL
    SELECT 'fields', COUNT(*) FROM fields
    UNION ALL
    SELECT 'stages', COUNT(*) FROM stages
    UNION ALL
    SELECT 'users', COUNT(*) FROM users
),

staging_counts AS (
    -- Counts from the STAGING Schema (e.g., pipedrive_analytics)
    SELECT 'activity' AS table_name, COUNT(*) AS stg_rows FROM pipedrive_analytics.stg_activities
    UNION ALL
    SELECT 'activity_types', COUNT(*) FROM pipedrive_analytics.stg_activity_types
    UNION ALL
    SELECT 'deal_changes', COUNT(*) FROM pipedrive_analytics.stg_deal_changes
    UNION ALL
    SELECT 'fields', COUNT(*) FROM pipedrive_analytics.stg_fields
    UNION ALL
    SELECT 'stages', COUNT(*) FROM pipedrive_analytics.stg_stages
    UNION ALL
    SELECT 'users', COUNT(*) FROM pipedrive_analytics.stg_users
)

-- Final Join to Compare Counts
SELECT
    COALESCE(r.table_name, s.table_name) AS table_or_model
    , r.raw_rows
    , s.stg_rows
    -- Difference should be zero or a small, expected number (e.g., filtering out bad rows)
    , COALESCE(r.raw_rows, 0) - COALESCE(s.stg_rows, 0) AS row_difference
    , CASE WHEN COALESCE(r.raw_rows, 0) = COALESCE(s.stg_rows, 0) 
           THEN 'MATCH'
           WHEN COALESCE(r.raw_rows, 0) > COALESCE(s.stg_rows, 0) 
           THEN 'FILTERED (Fewer staging rows)'
           ELSE 'ERROR (More staging rows)'
      END AS status
FROM raw_counts r
FULL OUTER JOIN staging_counts s
    ON r.table_name = s.table_name
ORDER BY 1;

-- Intermediate Tables Analysis

SELECT *
FROM pipedrive_analytics.int_activities;
--4579 rows (Matches raw data sources)

SELECT *
FROM pipedrive_analytics.int_activities_funnel;
-- 1128 rows (Matches with the raw data source analysis & stg sources)
/*
SELECT COUNT(DISTINCT activity_id) AS activity_count
FROM activity a
JOIN activity_types at
    ON a.type = at.type
WHERE TRUE
    AND LOWER(a.type) IN ('meeting', 'sc_2')
    AND done = 'true'
    AND active = 'Yes'

-- 1128
*/


SELECT *
FROM pipedrive_analytics.int_deal_stage_history;
-- 8906 rows (Matches with the stg source - stg_deal_changes)

/*

SELECT COUNT(DISTINCT deal_change_sk) 
FROM pipedrive_analytics.stg_deal_changes
WHERE deal_updated_field_key = 'stage_id'
--8906
*/

-- Reproting Layer Analyses 


SELECT *
FROM pipedrive_analytics.rep_months_funnel_grid;
-- 165 rows

SELECT *
FROM pipedrive_analytics.rep_sales_funnel_monthly;


-- QA CHECK FOR Deal count in activities
SELECT at.name AS activity_type
    , COUNT(DISTINCT activity_id) AS activity_count
FROM activity a
JOIN activity_types at
    ON a.type = at.type
WHERE TRUE
    AND LOWER(a.type) IN ('meeting', 'sc_2')
    AND done = 'true'
    AND active = 'Yes'
    AND DATE_TRUNC('month', due_to)::DATE = '2024-10-01'::DATE
GROUP BY 1;


-- QA Check : Raw vs Intermediate event count (per month)
WITH raw_filtered AS (
    SELECT
       MD5(
            COALESCE(deal_id::text,'') ||
            COALESCE(change_time::text,'') ||
            COALESCE(changed_field_key,'')
        ) AS deal_change_sk
        , deal_id
        , change_time
        , changed_field_key
        , new_value
        , s.stage_name
    FROM deal_changes dc
    JOIN stages s
        ON dc.new_value::int = s.stage_id 
    WHERE TRUE
        AND deal_id IS NOT NULL
        AND LOWER(changed_field_key) = 'stage_id'
        AND DATE_TRUNC('month', change_time)::DATE = '2024-05-01'::DATE
)
SELECT stage_name
    , COUNT( dc.deal_change_sk) AS deal_count
FROM raw_filtered dc
GROUP BY 1;


-- QA Check : First entry logic
-- RAW: first time each deal hit a stage
WITH raw_first AS (
    SELECT deal_id
        , new_value::int AS stage_id
        , MIN(change_time) AS raw_first_time
    FROM deal_changes
    WHERE LOWER(changed_field_key) = 'stage_id'
    GROUP BY 1,2
),

-- INTERMEDIATE
int_first AS (
    SELECT
        deal_id
        , stage_id
        , valid_from AS int_first_time
    FROM int_deal_stage_history
    WHERE is_first_entry = TRUE
)

SELECT *
FROM raw_first r
FULL JOIN int_first i
  ON r.deal_id = i.deal_id
 AND r.stage_id = i.stage_id
WHERE r.raw_first_time <> i.int_first_time
   OR r.raw_first_time IS NULL
   OR i.int_first_time IS NULL;

-- QA #3 — Count parity (sanity check)
SELECT
    (SELECT COUNT(*) 
     FROM deal_changes 
     WHERE LOWER(changed_field_key) = 'stage_id') AS raw_events,

    (SELECT COUNT(*) 
     FROM int_deal_stage_history) AS int_events;

   
SELECT DISTINCT kpi_name
FROM pipedrive_analytics.rep_sales_funnel_monthly;

-- QA Check: Intermediate vs Reporting
-- All raw stage change events
WITH raw AS (
    SELECT
        TO_CHAR(deal_change_timestamp, 'YYYY-MM') AS dt_month_string
        , deal_new_value::int AS stage_id
        , COUNT(*) AS raw_events
    FROM pipedrive_analytics.stg_deal_changes
    WHERE LOWER(deal_updated_field_key) = 'stage_id'
    GROUP BY 1,2
),
-- INTERMEDIATE: first stage entry per deal
int AS (
    SELECT
        TO_CHAR(valid_from, 'YYYY-MM') AS dt_month_string
        , stage_id
        , COUNT(DISTINCT deal_id) AS int_deals
    FROM pipedrive_analytics.int_deal_stage_history
    WHERE is_first_entry = TRUE
    GROUP BY 1,2
),
-- REPORTING: stage-based KPIs only
rep AS (
    SELECT
        month
        , funnel_step::int AS stage_id
        , deals_count AS rep_deals
    FROM pipedrive_analytics.rep_sales_funnel_monthly
    WHERE funnel_step IN (1,2,3,4,5,6,7,8,9)   -- stage KPIs only
)

SELECT
    COALESCE(r.dt_month_string, i.dt_month_string, p.month) AS month,
    COALESCE(r.stage_id, i.stage_id, p.stage_id) AS stage_id,
    r.raw_events,
    i.int_deals,
    p.rep_deals,
    (i.int_deals - p.rep_deals) AS int_vs_rep_diff
FROM raw r
FULL JOIN int i
  ON r.dt_month_string = i.dt_month_string AND r.stage_id = i.stage_id
FULL JOIN rep p
  ON COALESCE(r.dt_month_string, i.dt_month_string) = p.month
 AND COALESCE(r.stage_id, i.stage_id) = p.stage_id
ORDER BY 1,2;
-------------------------------------------------------------------------------------------------------------------------------------------


-- Query to show all the deal_id's in the stg_activity table that are not present in the stg_deal_changes table
SELECT DISTINCT(a.deal_id)
FROM pipedrive_analytics.stg_activities AS a
LEFT JOIN pipedrive_analytics.stg_deal_changes AS d
  ON a.deal_id = d.deal_id
WHERE d.deal_id IS NULL;
-- This shows 4564 deal_id's in the stg_activity table that are not present in the stg_deal_changes table


-- Query to show all the deal_id's in the stg_deal_changes table that are not present in the stg_activity table
SELECT DISTINCT(d.deal_id)
FROM pipedrive_analytics.stg_deal_changes AS d
LEFT JOIN pipedrive_analytics.stg_activities AS a
  ON d.deal_id = a.deal_id
WHERE a.deal_id IS NULL;
-- This shows 1987 deal_id's in the stg_deal_changes table that are not present in the stg_activity table

-------------------------------------------------------------------------------------------------------------------------------------------

 