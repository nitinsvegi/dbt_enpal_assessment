
    
    

select
    stage_id as unique_field,
    count(*) as n_records

from "postgres"."public_pipedrive_analytics"."stg_stages"
where stage_id is not null
group by stage_id
having count(*) > 1


