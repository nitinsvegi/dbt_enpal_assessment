{% macro generate_schema_name(custom_schema_name, node) %}
    {#
        Wrapper macro that dbt calls to determine the schema name.
        Simply delegates to custom_schema(node) for each model.
    #}
    {{ custom_schema(node) }}
{% endmacro %}
