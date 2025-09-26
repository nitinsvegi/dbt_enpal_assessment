
      
        
        
        delete from "postgres"."pipedrive_analytics"."stg_activity" as DBT_INTERNAL_DEST
        where (activity_id) in (
            select distinct activity_id
            from "stg_activity__dbt_tmp142459979577" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."pipedrive_analytics"."stg_activity" ("activity_id", "activity_type_short", "user_id", "deal_id", "is_activity_done_status", "activity_due_timestamp", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "activity_id", "activity_type_short", "user_id", "deal_id", "is_activity_done_status", "activity_due_timestamp", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "stg_activity__dbt_tmp142459979577"
    )
  