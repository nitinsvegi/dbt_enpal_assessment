{{ 
    config(
        materialized='view',
        tags= ['staging', 'stages']
    )
}}

-- Defines the funnel stages a deal can pass through (Lead Generation -> Qualified Lead -> Needs Assessment -> Proposal/ Quote Preparation -> Negotiation -> Closing -> Implementation/ Onboarding -> Follow-up/ Customer Success -> Renewal/Expansion)
-- Data comes from the raw 'stages' table in Postgres
-- Even though 'stages' already exists, staging it standardizes column names and ensures consistency for joins in downstream DBT models like rep_sales_funnel_monthly


WITH raw AS (

    SELECT *
    FROM {{ source('postgres_public', 'stages') }}
),

cleaned AS (
    
    SELECT
        stage_id::int AS stage_id
        , INITCAP(TRIM(stage_name)) AS stage_name
    FROM raw
    WHERE TRUE
        AND stage_id IS NOT NULL
)

SELECT *
FROM cleaned
ORDER BY stage_id