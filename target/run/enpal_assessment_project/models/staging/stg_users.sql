
      
  
    

  create  table "postgres"."public_pipedrive_analytics"."stg_users__dbt_tmp"
  
  
    as
  
  (
    

WITH raw AS (
    -- Pull the raw data from Postgres source
    SELECT *
    FROM "postgres"."public"."users"
),
cleaned AS (
    SELECT
        id as user_id
        , name AS user_name
        , email AS user_email
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp -- warehouse load timestamp
        , modified AS dwh_modified_timestamp
    FROM raw
    WHERE TRUE
        AND id is not null -- filter out any incomplete records
)

SELECT *
FROM cleaned


  );
  
  