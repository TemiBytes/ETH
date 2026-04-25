{{config(materialized='table')}}
with source as (
    select * from {{ ref('int_eth_transfers')}}
),
whale_transactions as (
    select 
        -- Identifiers
        hashkey,
        block_number,
        block_timestamp,
        tx_date,
        from_address,
        to_address,

        -- Value Columns
        value_wei,
        round(value_eth, 6) as value_eth_rounded,
        value_usd,

        -- Derived: tier classification based on USD value
        case
            when value_usd >= {{ var('mega_whale_threshold_usd') }} then 'mega_whale'
            when value_usd >= {{ var('large_whale_threshold_usd') }} then 'large_whale'
            when value_usd >= {{ var('whale_threshold_usd') }} then 'whale'
        end as whale_tier,

        -- Derived: daily rank by USD value descending
        row_number() over(partition by tx_date order by value_usd desc) as usd_rank,

        -- Derived: flag self transfers (from == to)
        case
            when from_address = to_address then true
            else false
        end as is_self_transfer,

        -- Passed through for context
        is_successful,
        transfer_type

    from source 
    where is_successful = true -- only consider successful transactions for whale analysis
    and value_usd >= {{ var('whale_threshold_usd') }} -- apply minimum threshold for whale classification
)
select * from whale_transactions