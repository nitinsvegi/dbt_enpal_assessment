
      
        
        
        delete from "postgres"."pipedrive_analytics"."stg_fields" as DBT_INTERNAL_DEST
        where (field_key) in (
            select distinct field_key
            from "stg_fields__dbt_tmp142500396001" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."pipedrive_analytics"."stg_fields" ("field_key", "field_name", "field_value_options", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "field_key", "field_name", "field_value_options", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "stg_fields__dbt_tmp142500396001"
    )
  