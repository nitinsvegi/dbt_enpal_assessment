{{ 
    config(
        materialized='incremental',
        unique_key='activity_event_sk',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        tags=['intermediate','activities']
    )
}}

WITH activities AS (

    SELECT *
    FROM {{ ref('stg_activities') }}

),

activity_types AS (

    SELECT *
    FROM {{ ref('stg_activity_types') }}

),

funnel_steps AS (

    SELECT *
    FROM {{ ref('funnel_steps') }}

),

enriched AS (

    SELECT
        a.activity_event_sk
        , a.activity_id
        , a.deal_id
        , a.user_id
        , a.activity_due_timestamp
        , a.is_activity_done_status
        , at.activity_type_id
        , at.activity_type_name
        , at.activity_type_short
        , at.is_activity_type_active
        , f.funnel_order_id
        , f.funnel_step
        , f.kpi_name
        , CURRENT_TIMESTAMP AS dwh_modified_timestamp
    FROM activities a
    LEFT JOIN activity_types at
        ON a.activity_type_short = at.activity_type_short
    LEFT JOIN funnel_steps f
        ON LOWER(TRIM(a.activity_type_short)) = LOWER(TRIM(f.activity_type_short))
)

SELECT *
FROM enriched