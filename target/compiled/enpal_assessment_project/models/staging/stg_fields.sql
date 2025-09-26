


-- Contains metadata about deal fields, including picklist values in JSON.
-- This is later unpacked to form dimension tables like `stages` and `lost_reasons`.

WITH raw AS (
    SELECT *
    FROM "postgres"."public"."fields"
),
cleaned AS (
    SELECT
        field_key
        , name AS field_name
        , field_value_options   -- JSON structure holding picklist values

        -- Represents picklist options for fields like stage_id or lost_reason.
        -- Examples:
        -- 1. stage_id → maps to stages table (stage_id, stage_name)
        -- 2. lost_reason → maps to stg_lost_reasons table (lost_reason_id, lost_reason_name)
        -- Fields like add_time or user_id have NULL because they are not picklists.

        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
        , CURRENT_TIMESTAMP AS dwh_modified_timestamp
    FROM raw
    WHERE TRUE
        AND field_key IS NOT NULL
)

SELECT *
FROM cleaned


    WHERE field_key NOT IN (SELECT field_key FROM "postgres"."pipedrive_analytics"."stg_fields")
