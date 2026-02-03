{{ 
    config(
        unique_key='deal_change_sk',
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        tags= ['staging', 'deal_changes']
    )
}}

-- Each deal can have multiple changes over time.

WITH raw AS (

    SELECT *
    FROM {{ source('postgres_public', 'deal_changes') }}
),

-- Deterministic surrogate key: identity = (deal_id, change_time, changed_field_key)
 raw_filtered AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            "COALESCE(deal_id::text,'')",
            "COALESCE(change_time::text,'')",
            "COALESCE(changed_field_key,'')"
        ]) }} AS deal_change_sk
        , deal_id
        , change_time
        , changed_field_key
        , new_value
    FROM raw
    WHERE deal_id IS NOT NULL
),

cleaned AS (
    
    SELECT
        deal_change_sk
        , deal_id
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
        , change_time AS deal_change_timestamp
        , LOWER(TRIM(changed_field_key)) AS deal_updated_field_key
        , NULLIF(new_value, '') AS deal_new_value
    FROM raw_filtered
)

SELECT *
FROM cleaned
{% if is_incremental() %}
WHERE deal_change_timestamp >= (
    SELECT COALESCE(MAX(deal_change_timestamp), '1900-01-01'::timestamp)
    FROM {{ this }}
)
{% endif %}
