
      
        
        
        delete from "postgres"."pipedrive_analytics"."stg_lost_reasons" as DBT_INTERNAL_DEST
        where (lost_reason_id) in (
            select distinct lost_reason_id
            from "stg_lost_reasons__dbt_tmp142501649496" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."pipedrive_analytics"."stg_lost_reasons" ("lost_reason_id", "lost_reason_name", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "lost_reason_id", "lost_reason_name", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "stg_lost_reasons__dbt_tmp142501649496"
    )
  