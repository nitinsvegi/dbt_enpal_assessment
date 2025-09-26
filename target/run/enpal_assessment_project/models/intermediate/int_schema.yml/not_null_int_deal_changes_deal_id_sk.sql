
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select deal_id_sk
from "postgres"."pipedrive_analytics"."int_deal_changes"
where deal_id_sk is null



  
  
      
    ) dbt_internal_test