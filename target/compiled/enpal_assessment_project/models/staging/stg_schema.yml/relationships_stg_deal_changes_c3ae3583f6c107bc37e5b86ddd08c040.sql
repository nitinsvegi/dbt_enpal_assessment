
    
    

with child as (
    select deal_updated_field_key as from_field
    from "postgres"."pipedrive_analytics"."stg_deal_changes"
    where deal_updated_field_key is not null
),

parent as (
    select field_key as to_field
    from "postgres"."pipedrive_analytics"."stg_fields"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


