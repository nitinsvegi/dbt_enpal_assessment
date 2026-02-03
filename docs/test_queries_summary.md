# Test Queries & Findings — Pipedrive source EDA

## Purpose
This file documents the exploratory queries used to validate Pipedrive source tables (activity, activity_types, users, fields, stages, deal_changes), plus key findings and recommended next actions.

## Where to find the runnable queries
`analyses/test_queries.sql` — contains all SQL used for the EDA, grouped by topic:
- Activity analysis
- Activity types
- Users & duplicates
- Fields / stages / deal_changes
- Cross-table QA checks
- Staging / Intermediate & reporting layer verification queries

## How to run
1. Ensure Docker + Postgres loader is running (or connect to the Postgres instance used in the assessment).
2. From the psql prompt or your SQL editor, copy-and-run sections.

## Key findings (short bullet summary)
- Duplicate activity_id: 11 cases; duplicates appear to represent different task states (e.g., done = false vs done = true) — likely CRM-level task versioning rather than straight data corruption.
- Activity Type distribution: After Close Call most frequent; sc_2 (Sales Call 2) least frequent — indicates follow-up/post-sale interactions are more common than multi-step sales calls.
- activity_types: All active types are referenced; follow_up_call appears in historical data but is now inactive.
- users: 1,787 users; no missing ids; 21 duplicate names (expected), 4 duplicate emails (likely placeholders/test accounts).
- Suggested policy: canonicalize by email where email is real (not placeholder), otherwise flag as suspect.
- fields / deal_changes / stages:
    - fields.field_value_options stores JSON picklists for stage_id and lost_reason.
    - stages is present and maps to stage_id.
    - lost_reason values exist only in JSON — a stg_lost_reasons (or seed) table is recommended.
    - deal_changes shows stage transitions, sometimes out-of-order or reversed — interpreted as reopened deals or reassignments.
- Cross-table:
    - deal_changes references ~1,995 distinct deals
    - activity references ~4,572 distinct deals
    - Only 8 deal_ids common between both tables → careful reconciliation required for funnel accuracy.

## Sample queries to re-run (short)

# QA Check — Deal counts by activity-type for a specific month
```
SELECT at.name AS activity_type
    , COUNT(DISTINCT a.activity_id) AS activity_count
FROM activity a
JOIN activity_types at
    ON a.type = at.type
WHERE TRUE
    AND LOWER(a.type) IN ('meeting', 'sc_2')
    AND a.done = 'true'
    AND at.active = 'Yes'
    AND DATE_TRUNC('month', a.due_to)::DATE = '2024-02-01'::DATE
GROUP BY 1;
```


# QA Check — Deal counts from deal_changes by stage for a month
```
WITH raw_filtered AS (
    SELECT
       MD5(
            COALESCE(deal_id::text,'') ||
            COALESCE(change_time::text,'') ||
            COALESCE(changed_field_key,'')
        ) AS deal_change_sk,
        deal_id,
        change_time,
        changed_field_key,
        new_value,
        s.stage_name
    FROM deal_changes dc
    JOIN stages s
        ON dc.new_value::int = s.stage_id 
    WHERE TRUE
        AND deal_id IS NOT NULL
        AND LOWER(changed_field_key) = 'stage_id'
        AND DATE_TRUNC('month', change_time)::DATE = '2024-05-01'::DATE
)
SELECT stage_name, COUNT(raw_filtered.deal_change_sk) AS deal_count
FROM raw_filtered
GROUP BY 1
ORDER BY 1;
```

# Compare raw vs staging row counts (sanity check)
```
WITH raw_counts AS (
    SELECT 'activity' AS table_name, COUNT(*) AS raw_rows FROM activity
    UNION ALL
    SELECT 'activity_types', COUNT(*) FROM activity_types
    UNION ALL
    SELECT 'deal_changes', COUNT(*) FROM deal_changes
    UNION ALL
    SELECT 'fields', COUNT(*) FROM fields
    UNION ALL
    SELECT 'stages', COUNT(*) FROM stages
    UNION ALL
    SELECT 'users', COUNT(*) FROM users
),

staging_counts AS (
    SELECT 'activity' AS table_name, COUNT(*) AS stg_rows FROM pipedrive_analytics.stg_activities
    UNION ALL
    SELECT 'activity_types', COUNT(*) FROM pipedrive_analytics.stg_activity_types
    UNION ALL
    SELECT 'deal_changes', COUNT(*) FROM pipedrive_analytics.stg_deal_changes
    UNION ALL
    SELECT 'fields', COUNT(*) FROM pipedrive_analytics.stg_fields
    UNION ALL
    SELECT 'stages', COUNT(*) FROM pipedrive_analytics.stg_stages
    UNION ALL
    SELECT 'users', COUNT(*) FROM pipedrive_analytics.stg_users
)

SELECT
    COALESCE(r.table_name, s.table_name) AS table_or_model,
    r.raw_rows,
    s.stg_rows,
    COALESCE(r.raw_rows, 0) - COALESCE(s.stg_rows, 0) AS row_difference,
    CASE WHEN COALESCE(r.raw_rows, 0) = COALESCE(s.stg_rows, 0) THEN 'MATCH'
         WHEN COALESCE(r.raw_rows, 0) > COALESCE(s.stg_rows, 0) THEN 'FILTERED (Fewer staging rows)'
         ELSE 'ERROR (More staging rows)'
    END AS status
FROM raw_counts r
FULL OUTER JOIN staging_counts s
    ON r.table_name = s.table_name
ORDER BY 1;
```

# Find deal_ids in activities not present in deal_changes
```
SELECT DISTINCT a.deal_id
FROM pipedrive_analytics.stg_activities a
LEFT JOIN pipedrive_analytics.stg_deal_changes d
  ON a.deal_id = d.deal_id
WHERE d.deal_id IS NULL
ORDER BY 1
LIMIT 100;
```

# Find deal_ids in deal_changes not present in activities
```
SELECT DISTINCT d.deal_id
FROM pipedrive_analytics.stg_deal_changes d
LEFT JOIN pipedrive_analytics.stg_activities a
  ON d.deal_id = a.deal_id
WHERE a.deal_id IS NULL
ORDER BY 1
LIMIT 100;
```

## Interpretation guidance — what to watch for
- Duplicate activity_id — determine business rule: do multiple rows represent lifecycle versions (keep latest / keep all / collapse)? Use done to disambiguate.
- Activity → deal linkage gap — only 8 deals in common between activities and deal_changes is a red flag. Investigate:
    - Are deal_id values created in different systems?
    - Are some activities generic (not tied to deals)?
- Stage rollbacks — backwards stage movement could mean deal reopenings; flag those in pipeline logic or treat them as valid transitions when computing funnel conversions.

## Recommended Next Actions
- Keep analyses/test_queries.sql for reproducible validation.
- Add dbt tests mirroring key EDA (Exploratory Data Analysis) checks:
    - Row counts and referential integrity across staging tables.
    - stg_deal_changes.deal_change_timestamp not null.
    - stg_deal_changes.deal_updated_field_key within accepted values.
    - Relationship tests for stg_lost_reasons and stg_stages.
- Normalize lost_reason into a dedicated seed/staging table.
- Add canonicalization logic for users (unique per valid email).
- Document observed anomalies (duplicate activities, stage rollbacks).