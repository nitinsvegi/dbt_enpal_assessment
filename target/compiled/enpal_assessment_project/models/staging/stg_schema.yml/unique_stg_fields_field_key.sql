
    
    

select
    field_key as unique_field,
    count(*) as n_records

from "postgres"."public_pipedrive_analytics"."stg_fields"
where field_key is not null
group by field_key
having count(*) > 1


