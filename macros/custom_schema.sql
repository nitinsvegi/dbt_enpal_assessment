{% macro custom_schema(model) %}
    {# 
        Determine the target schema for each model based on its tag. 
        Uses vars defined in dbt_project.yml to map models to custom schemas.
        Fallback to target.schema if the model isn't listed in the vars.
    #}
    {% set custom_schema = None %}
    {% if 'staging' in model.tags %}
        {% set custom_schema = var('stg_schemas', {}).get(model.name) %}
    {% elif 'intermediate' in model.tags %}
        {% set custom_schema = var('int_schemas', {}).get(model.name) %}
    {% elif 'reporting' in model.tags %}
        {% set custom_schema = var('rep_schemas', {}).get(model.name) %}
    {% endif %}
    {{ return(custom_schema or target.schema) }}
{% endmacro %}
