{% macro convert_to_usd(column_name)%}
    {{column_name}} * (select
        price
    from {{ ref('eth_usd_max')}}
    QUALIFY row_number() over (order by snapped_at desc) = 1)
{% endmacro %}