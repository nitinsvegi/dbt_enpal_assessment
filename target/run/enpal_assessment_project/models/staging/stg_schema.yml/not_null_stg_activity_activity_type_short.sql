
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select activity_type_short
from "postgres"."public_pipedrive_analytics"."stg_activity"
where activity_type_short is null



  
  
      
    ) dbt_internal_test