{{ 
    config(
        materialized='view',
        tags= ['staging', 'lost_reasons']
    )
}}

-- This table extracts all possible reasons a deal can be lost
-- Data comes from the 'field_value_options' JSON in stg_fields where field_key = 'lost_reason'
-- Each JSON object represents a lost reason with 'id' and 'name'

WITH raw AS (
    SELECT *
    FROM {{ ref('stg_fields') }}
    WHERE TRUE 
        AND LOWER(field_key) = 'lost_reason'
        AND field_value_options IS NOT NULL
),
unnested AS (
    -- Unnest the JSON array to get one row per lost reason
    SELECT
        CAST(v.value->>'id' AS INT) AS lost_reason_id   -- Unique identifier for the lost reason
        , INITCAP(TRIM(v.value->>'label')) AS lost_reason_name            -- Name of the lost reason
    FROM raw
    JOIN LATERAL jsonb_array_elements(field_value_options) AS v(value) ON TRUE -- Postgres function to expand JSON array into rows
)

SELECT *
FROM unnested
ORDER BY lost_reason_id