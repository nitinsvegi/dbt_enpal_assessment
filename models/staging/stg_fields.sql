{{ 
    config(
        materialized='view',
        tags= ['staging', 'fields']
    )
}}


-- Contains metadata about deal fields, including picklist values in JSON
-- This is later unpacked to form the `lost_reasons` staging tables 

WITH raw AS (

    SELECT *
    FROM {{ source('postgres_public', 'fields') }}
),

cleaned AS (
    
    SELECT
        id AS field_id
        , TRIM(LOWER(field_key)) AS field_key
        , TRIM(name) AS field_name
        , field_value_options   -- JSON structure holding picklist values
    FROM raw
    WHERE TRUE
        AND field_key IS NOT NULL
)

SELECT *
FROM cleaned