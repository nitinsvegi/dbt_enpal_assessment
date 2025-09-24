
    
    

select
    activity_id as unique_field,
    count(*) as n_records

from "postgres"."public_pipedrive_analytics"."int_activity"
where activity_id is not null
group by activity_id
having count(*) > 1


