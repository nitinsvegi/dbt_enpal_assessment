
      
        
        
        delete from "postgres"."pipedrive_analytics"."rep_sales_funnel_monthly" as DBT_INTERNAL_DEST
        where (month_year||funnel_step) in (
            select distinct month_year||funnel_step
            from "rep_sales_funnel_monthly__dbt_tmp142559319874" as DBT_INTERNAL_SOURCE
        );

    

    insert into "postgres"."pipedrive_analytics"."rep_sales_funnel_monthly" ("month_year", "kpi_name", "funnel_step", "deals_count")
    (
        select "month_year", "kpi_name", "funnel_step", "deals_count"
        from "rep_sales_funnel_monthly__dbt_tmp142559319874"
    )
  