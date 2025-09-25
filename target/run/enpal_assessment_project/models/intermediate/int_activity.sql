
      
        
        
        delete from "postgres"."public_pipedrive_analytics"."int_activity" as DBT_INTERNAL_DEST
        where (activity_id) in (
            select distinct activity_id
            from "int_activity__dbt_tmp102603494735" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."public_pipedrive_analytics"."int_activity" ("activity_id", "deal_id", "user_id", "user_name", "user_email", "activity_type_short", "is_activity_done_status", "activity_due_timestamp", "dwh_creation_timestamp", "dwh_modified_timestamp", "activity_type_name", "is_activity_type_active")
    (
        select "activity_id", "deal_id", "user_id", "user_name", "user_email", "activity_type_short", "is_activity_done_status", "activity_due_timestamp", "dwh_creation_timestamp", "dwh_modified_timestamp", "activity_type_name", "is_activity_type_active"
        from "int_activity__dbt_tmp102603494735"
    )
  