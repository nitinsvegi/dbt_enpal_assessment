{{ 
    config(
        unique_key='lost_reason_id',
        materialized='incremental',
        on_schema_change='sync_all_columns',
        tags= ['staging', 'lost_reasons']
    )
}}

-- This table extracts all possible reasons a deal can be lost.
-- Data comes from the 'field_value_options' JSON in stg_fields where field_key = 'lost_reason'.
-- Each JSON object represents a lost reason with 'id' and 'name'.

WITH raw AS (
    SELECT *
    FROM {{ ref('stg_fields') }}
    WHERE field_key = 'lost_reason'
),
unnested AS (
    -- Unnest the JSON array to get one row per lost reason
    SELECT
        CAST(v.value->>'id' AS INT) AS lost_reason_id,   -- Unique identifier for the lost reason
        v.value->>'label' AS lost_reason_name           -- Name of the lost reason
    FROM raw
    JOIN LATERAL jsonb_array_elements(field_value_options) AS v(value) ON TRUE -- Postgres function to expand JSON array into rows
),
cleaned AS (
    -- Add DWH tracking columns for auditing
    SELECT
        lost_reason_id
        , lost_reason_name
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
        , CURRENT_TIMESTAMP AS dwh_modified_timestamp   
    FROM unnested
)

SELECT *
FROM cleaned

{% if is_incremental() %}
    WHERE lost_reason_id NOT IN (SELECT lost_reason_id FROM {{ this }})
{% endif %}
