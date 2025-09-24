{{ 
    config(
        unique_key='activity_id',
        materialized='incremental',
        on_schema_change='sync_all_columns',
        tags=['intermediate', 'activity']
    )
}}

-- Intermediate model that enriches activities with descriptive user and activity type information. 
-- Keeps 1 row per activity_id (deduped in stg_activity).

WITH base AS (
    SELECT *
    FROM {{ ref('stg_activity') }}
),

user_enriched AS (
    SELECT
        b.activity_id
        , b.deal_id
        , b.user_id
        , u.user_name
        , u.user_email
        , b.activity_type_short
        , b.is_activity_done_status
        , b.activity_due_timestamp
        , b.dwh_creation_timestamp
        , b.dwh_modified_timestamp
    FROM base b
    LEFT JOIN {{ ref('stg_users') }} u
      ON b.user_id = u.user_id
),

activity_type_enriched AS (
    SELECT
        ue.*
        , at.activity_type_name
        , at.is_activity_type_active
    FROM user_enriched ue
    LEFT JOIN {{ ref('stg_activity_types') }} at
      ON ue.activity_type_short = at.activity_type_short
)

SELECT *
FROM activity_type_enriched

{% if is_incremental() %}
    WHERE activity_id NOT IN (SELECT activity_id FROM {{ this }})
{% endif %}
