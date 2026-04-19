{{config(materialized='table')}}
with source as (
    select * from {{ ref('int_eth_gas')}}
),

daily_gas_metrics as (
    select
        -- Grain: one row per dat per fee model type
        tx_date,
        is_eip1559,

        -- Volume: how many transactions in this group
        count(*) as tx_count,

        -- Gas price in Gwei (human readable standard unit)
        round(avg(gas_price) / 1e9,4) as avg_gas_price_gwei,

        -- Avg gas cost per transaction
        round(avg(gas_cost_eth),8) as avg_gas_cost_eth,
        round(avg(gas_cost_usd),4) as avg_gas_cost_usd,

        -- median gas cost (more representative than average)
        round(median(gas_cost_usd),4) as median_gas_cost_usd,

        -- most expensive single transaction fee for that day
        round(max(gas_cost_usd),4) as max_gas_cost_usd,

        -- Total ETH consumed in fees across all transactions
        round(sum(gas_cost_eth),6) as total_gas_spent_eth,

        -- Average utilitization of gas limits set by senders
        round(avg(gas_utilization_pct),2) as avg_gas_utilization_pct,

        -- EIP-1559 adoption rate across all transactions that day
        round(100.0 * sum(case when is_eip1559 then 1 else 0 end) / count(*),2) as eip1559_adoption_pct
    from source
    group by 1,2
)
select * from daily_gas_metrics
order by tx_date desc, is_eip1559 desc

