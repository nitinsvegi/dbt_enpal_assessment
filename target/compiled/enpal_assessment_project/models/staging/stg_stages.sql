

-- Defines the funnel stages a deal can pass through (Lead Generation -> Qualified Lead -> Needs Assessment -> Proposal/ Quote Preparation -> Negotiation -> Closing -> Implementation/ Onboarding -> Follow-up/ Customer Success -> Renewal/Expansion)
-- Data comes from the raw 'stages' table in Postgres.
-- Even though 'stages' already exists, staging it standardizes column names, adds DWH timestamps, 
-- and ensures consistency for joins in downstream DBT models like rep_sales_funnel_monthly.


WITH raw AS (
    SELECT *
    FROM "postgres"."public"."stages"
),
cleaned AS (
    SELECT
        stage_id
        , stage_name
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
        , CURRENT_TIMESTAMP AS dwh_modified_timestamp
    FROM raw
    WHERE TRUE
        AND stage_id IS NOT NULL
)

SELECT *
FROM cleaned


    WHERE stage_id NOT IN (SELECT stage_id FROM "postgres"."public_pipedrive_analytics"."stg_stages")
