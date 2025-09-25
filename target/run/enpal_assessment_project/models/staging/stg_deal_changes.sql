
      
        
        
        delete from "postgres"."public_pipedrive_analytics"."stg_deal_changes" as DBT_INTERNAL_DEST
        where (deal_id_sk) in (
            select distinct deal_id_sk
            from "stg_deal_changes__dbt_tmp102532024751" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."public_pipedrive_analytics"."stg_deal_changes" ("deal_id_sk", "deal_id", "deal_change_timestamp", "deal_updated_field_key", "deal_new_value", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "deal_id_sk", "deal_id", "deal_change_timestamp", "deal_updated_field_key", "deal_new_value", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "stg_deal_changes__dbt_tmp102532024751"
    )
  