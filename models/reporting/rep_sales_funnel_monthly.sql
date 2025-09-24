{{ 
    config(
        unique_key='month||funnel_step',
        materialized='incremental',
        on_schema_change='sync_all_columns',
        tags=['reporting', 'sales_funnel']
    )
}}

-- Aggregates deal and activity data to create a monthly sales funnel view.

-- Column definitions:
-- month: Month of the activity or stage change (first day of month)
-- kpi_name: Name of the KPI corresponding to the funnel step
-- funnel_step: Funnel step identifier (Step 1, Step 2.1, etc.)
-- deals_count: Count of unique deals in that month and funnel step

WITH
-- Stage-based funnel steps (from int_deal_changes)
stage_funnel AS (
    SELECT
        -- EXTRACT(MONTH FROM deal_change_timestamp) AS month
        TO_CHAR(deal_change_timestamp, 'MM-YYYY') AS month_year
        ,  CASE 
            WHEN stage_name = 'Lead Generation' THEN 'Stage: Lead Generation'
            WHEN stage_name = 'Qualified Lead' THEN 'Stage: Qualified Lead'
            WHEN stage_name = 'Needs Assessment' THEN 'Stage: Needs Assessment'
            WHEN stage_name = 'Proposal/Quote Preparation' THEN 'Stage: Proposal/Quote Preparation'
            WHEN stage_name = 'Negotiation' THEN 'Stage: Negotiation'
            WHEN stage_name = 'Closing' THEN 'Stage: Closing'
            WHEN stage_name = 'Implementation/Onboarding' THEN 'Stage: Implementation/Onboarding'
            WHEN stage_name = 'Follow-up/Customer Success' THEN 'Stage: Follow-up/Customer Success'
            WHEN stage_name = 'Renewal/Expansion' THEN 'Stage: Renewal/Expansion'
            ELSE NULL
          END AS kpi_name
        , CASE 
            WHEN stage_name = 'Lead Generation' THEN 'Step 1'
            WHEN stage_name = 'Qualified Lead' THEN 'Step 2'
            WHEN stage_name = 'Needs Assessment' THEN 'Step 3'
            WHEN stage_name = 'Proposal/Quote Preparation' THEN 'Step 4'
            WHEN stage_name = 'Negotiation' THEN 'Step 5'
            WHEN stage_name = 'Closing' THEN 'Step 6'
            WHEN stage_name = 'Implementation/Onboarding' THEN 'Step 7'
            WHEN stage_name = 'Follow-up/Customer Success' THEN 'Step 8'
            WHEN stage_name = 'Renewal/Expansion' THEN 'Step 9'
            ELSE NULL
          END AS funnel_step
        , deal_id
    FROM {{ ref('int_deal_changes') }}
    WHERE TRUE
        AND stage_name IS NOT NULL
),

-- Activity-based funnel steps (from int_activity)
activity_funnel AS (
    SELECT
        -- EXTRACT(MONTH FROM activity_due_timestamp) AS month
        TO_CHAR(activity_due_timestamp, 'MM-YYYY') AS month_year
        , CASE 
            WHEN activity_type_short = 'meeting' THEN 'Activity: Sales Call 1'
            WHEN activity_type_short = 'sc_2' THEN 'Activity: Sales Call 2'
            WHEN activity_type_short = 'follow_up' THEN 'Activity: Follow-up/Customer Success'
            WHEN activity_type_short = 'after_close_call' THEN 'Activity: Closing'
            ELSE NULL
          END AS kpi_name
        , CASE 
            WHEN activity_type_short = 'meeting' THEN 'Step 2.1'
            WHEN activity_type_short = 'sc_2' THEN 'Step 3.1'
            WHEN activity_type_short = 'after_close_call' THEN 'Step 6'
            WHEN activity_type_short = 'follow_up' THEN 'Step 8'
            ELSE NULL
         END AS funnel_step
        , deal_id
    FROM {{ ref('int_activity') }}
    WHERE TRUE
        AND activity_type_short IN ('meeting','sc_2','follow_up','after_close_call')
),

-- Lost Reason-based funnel steps (from int_deal_changes)
lost_reason_funnel AS (
    SELECT
        TO_CHAR(deal_change_timestamp, 'MM-YYYY') AS month_year
        , CASE 
            WHEN lost_reason_name = 'Customer Not Ready' THEN 'Lost Reason: Customer Not Ready'
            WHEN lost_reason_name = 'Pricing Issues' THEN 'Lost Reason: Pricing Issues'
            WHEN lost_reason_name = 'Unreachable Customer' THEN 'Lost Reason: Unreachable Customer'
            WHEN lost_reason_name = 'Product Mismatch' THEN 'Lost Reason: Product Mismatch'
            WHEN lost_reason_name = 'Duplicate Entry' THEN 'Lost Reason: Duplicate Entry'
            ELSE NULL
        END AS kpi_name
        , CASE 
            WHEN lost_reason_name = 'Customer Not Ready' THEN 'Step 1'
            WHEN lost_reason_name = 'Pricing Issues' THEN 'Step 2'
            WHEN lost_reason_name = 'Unreachable Customer' THEN 'Step 3'
            WHEN lost_reason_name = 'Product Mismatch' THEN 'Step 4'
            WHEN lost_reason_name = 'Duplicate Entry' THEN 'Step 5'
            ELSE NULL
        END AS funnel_step
        , deal_id
    FROM {{ ref('int_deal_changes') }}
    WHERE TRUE
    AND lost_reason_name IS NOT NULL
),

-- Union all funnel events
all_funnel AS (
    SELECT * FROM stage_funnel
    UNION ALL
    SELECT * FROM activity_funnel
    UNION ALL
    SELECT * FROM lost_reason_funnel
),

-- Aggregate by month-year + funnel step
aggregated AS (
    SELECT
        month_year
        , kpi_name
        , funnel_step
        , COUNT(DISTINCT deal_id) AS deals_count
    FROM all_funnel
    WHERE kpi_name IS NOT NULL
    GROUP BY 1,2,3
)

SELECT *
FROM aggregated

{% if is_incremental() %}
    WHERE CONCAT(month, funnel_step) NOT IN 
          (SELECT CONCAT(month, funnel_step) FROM {{ this }})
{% endif %}
