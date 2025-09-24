
    
    

with child as (
    select activity_type_short as from_field
    from "postgres"."public_pipedrive_analytics"."stg_activity"
    where activity_type_short is not null
),

parent as (
    select activity_type_short as to_field
    from "postgres"."public_pipedrive_analytics"."stg_activity_types"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


