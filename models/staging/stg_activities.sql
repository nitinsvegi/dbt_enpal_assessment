{{ 
    config(
        materialized='incremental',
        unique_key='activity_event_sk',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        tags=['staging', 'activities']
    )
}}


WITH raw AS (
    
    SELECT *
    FROM {{ source('postgres_public', 'activity') }}
),

cleaned AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            "activity_id",
            "assigned_to_user",
            "due_to"
        ]) }} AS activity_event_sk
        , activity_id
        , type AS activity_type_short
        , assigned_to_user AS user_id
        , deal_id
        , done AS is_activity_done_status
        , due_to AS activity_due_timestamp
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
    FROM raw
    WHERE activity_id IS NOT NULL
)

SELECT * FROM cleaned