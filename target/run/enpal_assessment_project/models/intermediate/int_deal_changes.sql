
      
        
        
        delete from "postgres"."pipedrive_analytics"."int_deal_changes" as DBT_INTERNAL_DEST
        where (deal_id_sk) in (
            select distinct deal_id_sk
            from "int_deal_changes__dbt_tmp142535432194" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."pipedrive_analytics"."int_deal_changes" ("deal_id_sk", "deal_id", "deal_change_timestamp", "deal_updated_field_key", "deal_new_value", "stage_name", "lost_reason_name", "dwh_creation_timestamp", "dwh_modified_timestamp")
    (
        select "deal_id_sk", "deal_id", "deal_change_timestamp", "deal_updated_field_key", "deal_new_value", "stage_name", "lost_reason_name", "dwh_creation_timestamp", "dwh_modified_timestamp"
        from "int_deal_changes__dbt_tmp142535432194"
    )
  