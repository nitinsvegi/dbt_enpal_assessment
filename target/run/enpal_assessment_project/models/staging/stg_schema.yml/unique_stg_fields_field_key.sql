
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    field_key as unique_field,
    count(*) as n_records

from "postgres"."public_pipedrive_analytics"."stg_fields"
where field_key is not null
group by field_key
having count(*) > 1



  
  
      
    ) dbt_internal_test