
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select user_id
from "postgres"."public_pipedrive_analytics"."stg_activity"
where user_id is null



  
  
      
    ) dbt_internal_test