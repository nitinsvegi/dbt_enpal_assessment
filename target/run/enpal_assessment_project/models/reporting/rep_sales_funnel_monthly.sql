
      
        
        
        delete from "postgres"."public_pipedrive_analytics"."rep_sales_funnel_monthly" as DBT_INTERNAL_DEST
        where (month_year||funnel_step) in (
            select distinct month_year||funnel_step
            from "rep_sales_funnel_monthly__dbt_tmp102644425092" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."public_pipedrive_analytics"."rep_sales_funnel_monthly" ("month_year", "kpi_name", "funnel_step", "deals_count")
    (
        select "month_year", "kpi_name", "funnel_step", "deals_count"
        from "rep_sales_funnel_monthly__dbt_tmp102644425092"
    )
  