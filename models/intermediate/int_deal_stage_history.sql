{{ 
    config(
        materialized='incremental',
        unique_key='deal_stage_history_sk',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        tags=['intermediate','deal']
    )
}}

-- Only stage change events
WITH stage_events AS (

    SELECT
        deal_id
        , CAST(deal_new_value AS INT) AS stage_id
        , deal_change_timestamp
    FROM {{ ref('stg_deal_changes') }}
    WHERE deal_updated_field_key = 'stage_id'
      AND deal_new_value ~ '^[0-9]+$'

),

-- Order stage movements per deal
ordered AS (

    SELECT
        deal_id
        , stage_id
        , deal_change_timestamp AS valid_from

        , LEAD(deal_change_timestamp) OVER (
              PARTITION BY deal_id
              ORDER BY deal_change_timestamp
          ) AS valid_to

        , ROW_NUMBER() OVER (
             PARTITION BY deal_id, stage_id
             ORDER BY deal_change_timestamp
        ) AS stage_entry_rank

    FROM stage_events
),

-- Keep state history + mark first entry into stage
history AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            "deal_id",
            "stage_id",
            "valid_from"
        ]) }} AS deal_stage_history_sk

        , deal_id
        , stage_id
        , valid_from
        , valid_to
        , CASE WHEN stage_entry_rank = 1 
               THEN TRUE 
               ELSE FALSE 
          END AS is_first_entry
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
    FROM ordered
)

SELECT *
FROM history
{% if is_incremental() %}
WHERE valid_from > (
    SELECT COALESCE(MAX(valid_from), '1900-01-01'::timestamp)
    FROM {{ this }}
)
{% endif %}