
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select stage_id
from "postgres"."pipedrive_analytics"."stg_stages"
where stage_id is null



  
  
      
    ) dbt_internal_test