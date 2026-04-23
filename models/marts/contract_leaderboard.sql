{{config(materialized='table')}}

with source as (
    select 
        *
    from {{ref('int_eth_contract_activity')}}
    -- only count actual usage, not deployment events
    where transfer_type = 'contract_interaction'
    and contract_address is not null
),

-- Aggregate to one row per contract
contract_stats as (
    select
        contract_address,

        -- Activity volume
        count(*) as total_interactions,
        sum(case when is_successful then 1 else 0 end) as successful_interactions,
        -- success rate
        round(sum(case when is_successful then 1 else 0 end)/nullif(count(*), 0), 2) as success_rate_pct,
        -- unique callers (breadth of adoption)
        count(distinct from_address) as unique_callers,
        -- ETH economic weight
        round(sum(value_eth), 6) as total_eth_received,
        round(avg(value_eth), 6) as avg_eth_per_interaction,
        round(sum(value_usd), 2) as total_usd_received,
        -- call complexitity proxy
        round(avg(input_data_length), 0) as avg_input_data_length,
        -- contract lifespan in dataset
        min(block_timestamp) as first_interaction,
        max(block_timestamp) as last_interaction
    from source
    group by contract_address
),

-- add global ranking columns
ranked as (
    select 
        *,
        -- rank by interaction count(most called = rank 1)
        row_number() over (order by total_interactions desc) as activity_rank,
        -- rank by ETH received (most ETH received = rank 1)
        row_number() over (order by total_eth_received desc) as eth_rank
    from contract_stats
),

-- apply tier classification using activit_rank
final as  (
    select
        *,
        -- tier based on activity_rank
        case 
            when activity_rank <= 10 then 'tier_1'
            when activity_rank <= 100 then 'tier_2'
            when activity_rank <= 1000 then 'tier_3'
            else 'long_tail'
        end as contract_tier
    from ranked
)
select * from final
order by activity_rank asc