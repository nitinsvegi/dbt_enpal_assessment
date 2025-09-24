
    
    

with child as (
    select deal_id as from_field
    from "postgres"."public_pipedrive_analytics"."stg_activity"
    where deal_id is not null
),

parent as (
    select deal_id as to_field
    from "postgres"."public_pipedrive_analytics"."stg_deal_changes"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


