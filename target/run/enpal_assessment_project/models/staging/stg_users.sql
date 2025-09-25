
      
        
        
        delete from "postgres"."public_pipedrive_analytics"."stg_users" as DBT_INTERNAL_DEST
        where (user_id) in (
            select distinct user_id
            from "stg_users__dbt_tmp102532200908" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."public_pipedrive_analytics"."stg_users" ("user_id", "user_name", "user_email", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "user_id", "user_name", "user_email", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "stg_users__dbt_tmp102532200908"
    )
  