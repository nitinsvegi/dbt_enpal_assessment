SELECT *
FROM {{ source('postgres_public','activity') }}