
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select month_year
from "postgres"."public_pipedrive_analytics"."rep_sales_funnel_monthly"
where month_year is null



  
  
      
    ) dbt_internal_test