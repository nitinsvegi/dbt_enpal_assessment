
    
    

select
    deal_id_sk as unique_field,
    count(*) as n_records

from "postgres"."public_pipedrive_analytics"."stg_deal_changes"
where deal_id_sk is not null
group by deal_id_sk
having count(*) > 1


