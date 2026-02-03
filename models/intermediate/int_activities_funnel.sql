{{ 
    config(
        materialized='incremental',
        unique_key='deal_activity_funnel_sk',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        tags=['intermediate','activities','funnel']
    )
}}

WITH base AS (

    SELECT *
    FROM {{ ref('int_activities') }}
    WHERE is_activity_done_status = TRUE
      AND is_activity_type_active = 'Yes'
      AND funnel_order_id IS NOT NULL   -- only mapped funnel steps

),

ranked AS (

    SELECT
        deal_id
        , funnel_order_id
        , funnel_step
        , kpi_name
        , activity_due_timestamp AS valid_from

        , ROW_NUMBER() OVER (
             PARTITION BY deal_id, funnel_order_id
             ORDER BY activity_due_timestamp
         ) AS entry_rank

    FROM base
    WHERE deal_id IS NOT NULL

),

first_entries AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            "deal_id",
            "funnel_order_id",
            "valid_from"
        ]) }} AS deal_activity_funnel_sk

        , deal_id
        , funnel_order_id
        , funnel_step
        , kpi_name
        , valid_from
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp

    FROM ranked
    WHERE entry_rank = 1  -- first time deal achieved this step

)

SELECT *
FROM first_entries
{% if is_incremental() %}
WHERE valid_from > (
    SELECT COALESCE(MAX(valid_from), '1900-01-01'::timestamp)
    FROM {{ this }}
)
{% endif %}