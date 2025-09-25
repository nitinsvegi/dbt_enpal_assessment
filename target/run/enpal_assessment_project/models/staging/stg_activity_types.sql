
      
        
        
        delete from "postgres"."public_pipedrive_analytics"."stg_activity_types" as DBT_INTERNAL_DEST
        where (activity_type_id) in (
            select distinct activity_type_id
            from "stg_activity_types__dbt_tmp102531961649" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."public_pipedrive_analytics"."stg_activity_types" ("activity_type_id", "activity_type_name", "is_activity_type_active", "activity_type_short", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "activity_type_id", "activity_type_name", "is_activity_type_active", "activity_type_short", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "stg_activity_types__dbt_tmp102531961649"
    )
  