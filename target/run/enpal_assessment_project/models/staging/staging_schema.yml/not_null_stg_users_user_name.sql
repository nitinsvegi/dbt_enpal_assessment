
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select user_name
from "postgres"."public_pipedrive_analytics"."stg_users"
where user_name is null



  
  
      
    ) dbt_internal_test