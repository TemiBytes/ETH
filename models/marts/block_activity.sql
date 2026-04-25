-- models/marts/block_activity.sql

{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_eth') }}
),

block_stats as (
    select
        -- Grain: one row per block
        block_number,
        min(block_timestamp)                    as block_timestamp,
        min(tx_date)                            as tx_date,

        -- Transaction counts
        count(*)                                as tx_count,
        count(
            case when receipt_status = 1 then 1 end
        )                                       as successful_tx_count,
        count(
            case when receipt_status = 0 then 1 end
        )                                       as failed_tx_count,

        -- Failure rate
        round(
            100.0 * count(case when receipt_status = 0 then 1 end)
            / count(*),
            2
        )                                       as failure_rate_pct,

        -- Participant diversity
        count(distinct from_address)            as unique_senders,
        count(distinct to_address)              as unique_receivers,

        -- Economic throughput
        round(
            sum(value_wei) / 1e18, 6
        )                                       as total_eth_transferred,

        -- Gas metrics
        sum(receipt_gas_used)                   as total_gas_used,
        round(
            100.0 * sum(receipt_gas_used)
            / nullif(max(gas), 0),
            2
        )                                       as block_gas_utilization_pct,
        round(
            avg(gas_price) / 1e9, 4
        )                                       as avg_gas_price_gwei,

        -- Transaction type breakdown
        count(
            case when input = '0x' then 1 end
        )                                       as eth_transfer_count,
        count(
            case
                when input != '0x'
                and receipt_contract_address is null
                then 1
            end
        )                                       as contract_interaction_count,
        count(
            case
                when receipt_contract_address is not null
                then 1
            end
        )                                       as contract_creation_count

    from source
    group by block_number
),

-- Derive block type from transaction type proportions
final as (
    select
        *,

        -- Derived: what kind of block was this?
        case
            when div0(contract_interaction_count * 100.0, tx_count) > 70
                then 'contract_heavy'
            when div0(eth_transfer_count * 100.0, tx_count) > 70
                then 'transfer_heavy'
            else
                'mixed'
        end                                     as block_type

    from block_stats
)

select * from final
order by block_number desc