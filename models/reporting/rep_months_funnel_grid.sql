{{ 
    config(
        materialized='table',
        tags=['reporting', 'funnel', 'grid']
    )
}}

  WITH date_range AS (
    -- Step 1: Find the absolute min and max date across both tables
    SELECT
        MIN(min_date) AS min_date
        , MAX(max_date) AS max_date
    FROM (
        SELECT MIN(activity_due_timestamp) AS min_date
            , MAX(activity_due_timestamp) AS max_date 
        FROM {{ ref('stg_activities') }}
        
        UNION ALL
        
        SELECT MIN(deal_change_timestamp) AS min_date
            , MAX(deal_change_timestamp) AS max_date 
        FROM {{ ref('stg_deal_changes') }}
    ) AS combined_dates
),
month_series AS (
    -- Step 2: Generate the series of months
SELECT
    generate_series(
      date_trunc('month', date_range.min_date),
      date_trunc('month', date_range.max_date),
      interval '1 month'
    )::date as dt_month
  from date_range
  where date_range.min_date is not null and date_range.max_date is not null
),
final AS (
SELECT
    -- Step 3: Format the month series results
    dt_month
    , TO_CHAR(dt_month, 'YYYY-MM') AS dt_month_string
FROM month_series
ORDER BY dt_month
)
SELECT
    dt_month
    , dt_month_string
    , funnel_order_id
    , funnel_step
    , kpi_name
FROM final
CROSS JOIN {{ ref('funnel_steps') }} fs