{#
    Por padrão, o dbt cria schemas como "<schema_do_profile>_<schema_customizado>"
    (ex: "default_silver"). Como a gente já define +schema: silver / +schema: gold
    no dbt_project.yml pra representar as camadas do medalhão, queremos que o nome
    final seja exatamente "silver" ou "gold" - sem prefixo do profile.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
