{{ config(
    materialized='table',
    unique_key=['month','kpi_name'],
    tags=['reporting','funnel','monthly']
) }}

-- Stage-based funnel entries
WITH stage_entries AS (

    SELECT
        DATE_TRUNC('month', valid_from)::date AS dt_month
        , fs.funnel_order_id
        , COUNT(DISTINCT deal_id) AS deals_count
    FROM {{ ref('int_deal_stage_history') }} dsh
    JOIN {{ ref('funnel_steps') }} fs
      ON dsh.stage_id = fs.stage_id
    WHERE is_first_entry = TRUE
    GROUP BY 1,2
),

-- Activity-based funnel entries
activity_entries AS (

    SELECT
        DATE_TRUNC('month', valid_from)::date AS dt_month
        , funnel_order_id
        , COUNT(DISTINCT deal_id) AS deals_count
    FROM {{ ref('int_activities_funnel') }}
    GROUP BY 1,2
),

-- Combine facts
combined AS (

    SELECT * FROM stage_entries
    UNION ALL
    SELECT * FROM activity_entries
),

aggregated AS (

    SELECT
        dt_month
        , funnel_order_id
        , SUM(deals_count) AS deals_count
    FROM combined
    GROUP BY 1,2
)

-- Join to grid for zero-filling
SELECT
    g.dt_month_string AS month
    , g.kpi_name
    , g.funnel_step
    , COALESCE(a.deals_count, 0) AS deals_count
FROM {{ ref('rep_months_funnel_grid') }} g
LEFT JOIN aggregated a
  ON g.dt_month = a.dt_month
 AND g.funnel_order_id = a.funnel_order_id
ORDER BY g.dt_month, g.funnel_order_id