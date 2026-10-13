-- Use the custom schema name as-is (SILVER, GOLD, TEST_FAILURES)
-- instead of dbt's default <target_schema>_<custom_schema> (e.g. SILVER_GOLD).
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim | upper }}
    {%- endif -%}
{%- endmacro %}
