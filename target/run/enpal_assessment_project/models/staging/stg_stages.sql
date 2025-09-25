
      
        
        
        delete from "postgres"."public_pipedrive_analytics"."stg_stages" as DBT_INTERNAL_DEST
        where (stage_id) in (
            select distinct stage_id
            from "stg_stages__dbt_tmp102532147082" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."public_pipedrive_analytics"."stg_stages" ("stage_id", "stage_name", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "stage_id", "stage_name", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "stg_stages__dbt_tmp102532147082"
    )
  