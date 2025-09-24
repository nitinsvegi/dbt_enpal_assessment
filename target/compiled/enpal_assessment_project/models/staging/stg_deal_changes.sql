

-- Each deal can have multiple changes over time.
-- We create a surrogate key (`deal_id_sk`) to uniquely identify each row.
-- The combination of (change_time, changed_field_key, new_value) guarantees deterministic ordering.


WITH raw AS (
    SELECT *
    FROM "postgres"."public"."deal_changes"
),
deduped AS (
    SELECT
        deal_id
        , change_time
        , changed_field_key
        , new_value
        , ROW_NUMBER() OVER (
            PARTITION BY deal_id
            ORDER BY change_time, changed_field_key, new_value  -- Tie-breaker added using changed_field_key & new_value to ensure uniqueness if change_time is the same.
          ) AS rn
    FROM raw
),
cleaned AS (
    SELECT
        -- Create unique surrogate key as string
        CONCAT(deal_id, '_', rn) AS deal_id_sk
        , deal_id
        , change_time AS deal_change_timestamp
        , changed_field_key AS deal_updated_field_key
        , new_value AS deal_new_value
        , CURRENT_TIMESTAMP AS dwh_creation_timestamp
        , CURRENT_TIMESTAMP AS dwh_modified_timestamp
    FROM deduped
)

SELECT *
FROM cleaned

