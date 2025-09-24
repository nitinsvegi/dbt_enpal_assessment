-- Check the current user of the database
SELECT current_user;

-- Check the current database
SELECT current_database();

----------------------------------------------------------------------------------------------------------------------------------------
-- activity table analysis


SELECT * 
FROM activity
ORDER BY activity_id DESC;

SELECT DISTINCT(at.name) AS activity_name
    , COUNT(*) AS activity_count
FROM activity
LEFT JOIN activity_types at
    ON at.type = activity.type
GROUP BY 1
ORDER BY activity_count DESC;
 
-- After Close Call (type : after_close_call) has the highest activity count & Sales Call 2 (type : sc_2) has the lowest activity count
-- while Sales Call 1 (type : meeting) has the second highest activity count and Follow Up Call (type : follow_up_call) has the second lowest activity count

SELECT activity_id
    , COUNT(*) AS count
FROM activity
GROUP BY 1
HAVING COUNT(*) > 1;

-- Found duplicate activity_id's
     
SELECT *
FROM activity
WHERE TRUE
    AND activity_id IN (
        SELECT activity_id
        FROM activity
        GROUP BY 1
        HAVING COUNT(*) > 1
    )
ORDER BY activity_id;

-- Same activity_id's assigned to different user_id's with different deal_id's
-- also same activity_id's with different type's and different created_at's
-- this could be due to data entry errors, system glitches, or intentional duplication for tracking purposes

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

-- No duplicate user id's found

-- activity + user table join to find out which users in the activity table are not present in the user table

SELECT DISTINCT(a.assigned_to_user) AS activity_user_id
    , u.id AS user_id 
FROM activity a
LEFT JOIN users u 
    ON a.assigned_to_user = u.id
WHERE TRUE
    AND u.id IS NULL
ORDER BY user_id;

-- No users found in activity table that are not present in the user table
-- This indicates that all users assigned to activities are valid users in the system

----------------------------------------------------------------------------------------------------------------------------------------
-- fields + stages + deal_changes table analysis

SELECT * 
FROM fields;
-- there are 4 unique field keys

SELECT * 
FROM stages;
-- there are 9 unique stages

SELECT * 
FROM deal_changes;
-- The deal_changes table has multiple rows for the same deal_id, indicating that a single deal can undergo multiple changes over time

SELECT DISTINCT(changed_field_key) AS field_key
FROM deal_changes;

SELECT * 
FROM deal_changes
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
8. A deal can have stage_id skipped while progressing through different stages
   -- example, deal_id 100086 has stage_id 1, 3, 4, 6, 7 ; stage_id 2, 5, 8 & 9 is skipped
9. The changed_time column in the deal_changes table indicates the timestamp when the change was made
10. When a new deal is defined on the deal_changes table, the changed_field_key column has values that are representative of the 
   field_keys column in the fields table and the new_column value on the deal_changes table has values that are representative of 
   the field_value_option
   -- example 1, if a deal requires an update on the 'add_time' field, the fields table has a row with field_key = 'add_time' with
   a field_value_option of NULL; and the deal_changes table will have a row with changed_field_key = 'add_time' with a date-time  
   value inputted in new_value
   -- example 2, if a deal requires an update on the 'user_id' field, the fields table has a row with field_key = 'user_id' with
   a field_value_option of NULL; and the deal_changes table will have a row with changed_field_key = 'user_id' with a new integer 
   user id is inputted in new_value
   -- example 3, if a deal requires an update on the 'stage_id' field, the fields table has a row with field_key = 'stage_id' with
   a field_value_option of json array with key-value pairs of stage_id & stage_name from the stages tabls; and the deal_changes 
   table will have a row with changed_field_key = 'stage_id' with a new integer stage id is inputted in new_value
   -- example 4, if a deal requires an update on the 'lost_reason' field, once a new pick-list table (lets call it lost_reasons 
   with columns lost_reason_id & lost_reason_name) is created, the fields table has a row with field_key = 'lost_reason' with a 
   field_value_option of json array with key-value pairs of lost_reason_id & lost_reason_name; and the deal_changes table will have 
   a row with changed_field_key = 'lost_reason' with a new integer lost_reason id is inputted in new_value
11. A new old_value column can be created in the deal_changes table contains the previous values before the change was made

*/

----------------------------------------------------------------------------------------------------------------------------------------

SELECT * 
FROM activity
WHERE TRUE
    AND deal_id IN (
        SELECT deal_id
        FROM deal_changes
        WHERE TRUE
    )
ORDER BY activity_id, deal_id
LIMIT 100;

SELECT
    deal_id,
    COUNT(*) AS activity_count
FROM activity
GROUP BY deal_id
ORDER BY activity_count DESC;

-- confirm one deal has multiple activities.


SELECT
    deal_id,
    COUNT(*) AS deal_change_count
FROM deal_changes
GROUP BY deal_id
ORDER BY deal_change_count DESC;

-- confirms one deal has multiple deal_changes.

----------------------------------------------------------------------------------------------------------------------------------------
-- Staging Tables Analysis

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name ILIKE 'stg_users';

SELECT *
FROM public_pipedrive_analytics.stg_users
ORDER BY user_id DESC  
LIMIT 100;

-------------------------------------------------------------------------------------------------------------------------------------------
