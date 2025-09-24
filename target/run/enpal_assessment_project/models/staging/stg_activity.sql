
      
  
    

  create  table "postgres"."public_pipedrive_analytics"."stg_activity__dbt_tmp"
  
  
    as
  
  (
    

WITH raw AS (
    -- Pull the raw data from Postgres source
    SELECT *
    FROM "postgres"."public"."activity"
),

deduped AS (
    -- Deduplication logic:
    -- In raw data, sometimes the same activity_id may appear more than once 
    -- Since activity_id should uniquely represent an activity, we keep only the latest record.

    -- NOTE: In some edge cases, the same activity_id can have different user_id values. 
    -- This could usually happens when ownership or responsibility for an activity changes over time.
    -- To resolve this, we use `due_to` (latest timestamp) as the tie-breaker and keep the most recent assignment.
    -- This enforces one activity_id = one activity, aligned with how reporting expects unique activity records.
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY activity_id ORDER BY due_to DESC) AS rn
        FROM raw
    ) t
    WHERE rn = 1
),
cleaned AS (
    SELECT
        activity_id
        , type AS activity_type_short
        , assigned_to_user AS user_id
        , deal_id
        , done AS is_activity_done_status
        , due_to AS activity_due_timestamp
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
        , CURRENT_TIMESTAMP AS dwh_modified_timestamp
    FROM deduped
    WHERE TRUE
        AND activity_id IS NOT NULL
)

SELECT *
FROM cleaned


  );
  
  