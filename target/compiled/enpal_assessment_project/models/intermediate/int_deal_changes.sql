

-- Intermediate model that enriches deal changes with descriptive fields such as stage name or lost reason name. 
-- Keeps 1 row per deal change (normalized, auditable history).

WITH base AS (
    SELECT *
    FROM "postgres"."pipedrive_analytics"."stg_deal_changes"
),

-- Bring in stage names when the change refers to stage_id
stage_enriched AS (
    SELECT
        b.deal_id_sk
        , b.deal_id
        , b.deal_change_timestamp
        , b.deal_updated_field_key
        , b.deal_new_value
        , s.stage_name
        , NULL AS lost_reason_name
        , b.dwh_creation_timestamp
        , b.dwh_modified_timestamp
    FROM base b
    LEFT JOIN "postgres"."pipedrive_analytics"."stg_stages" s
     ON b.deal_new_value = CAST(s.stage_id AS TEXT)
    WHERE TRUE
        AND b.deal_updated_field_key = 'stage_id'
),

-- Bring in lost reason names when the change refers to lost_reason
lost_reason_enriched AS (
    SELECT
        b.deal_id_sk
        , b.deal_id
        , b.deal_change_timestamp
        , b.deal_updated_field_key
        , b.deal_new_value
        , NULL AS stage_name
        , lr.lost_reason_name
        , b.dwh_creation_timestamp
        , b.dwh_modified_timestamp
    FROM base b
    LEFT JOIN "postgres"."pipedrive_analytics"."stg_lost_reasons" lr
     ON  b.deal_new_value = CAST(lr.lost_reason_id AS TEXT)
    WHERE TRUE
        AND b.deal_updated_field_key = 'lost_reason'
),

final AS (
    SELECT
        deal_id_sk
        , deal_id
        , deal_change_timestamp
        , deal_updated_field_key
        , deal_new_value
        , stage_name
        , lost_reason_name
        , dwh_creation_timestamp
        , dwh_modified_timestamp
    FROM stage_enriched
UNION ALL
    SELECT
        deal_id_sk
        , deal_id
        , deal_change_timestamp
        , deal_updated_field_key
        , deal_new_value
        , stage_name
        , lost_reason_name
        , dwh_creation_timestamp
        , dwh_modified_timestamp
    FROM lost_reason_enriched
)

SELECT *
FROM final


    WHERE deal_id_sk NOT IN (SELECT deal_id_sk FROM "postgres"."pipedrive_analytics"."int_deal_changes")
