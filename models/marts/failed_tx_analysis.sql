-- models/marts/failed_tx_analysis.sql

{{ config(materialized='table') }}

with source as (
    select * from {{ ref('stg_eth') }}
    where receipt_status = 0
),

failed_transactions as (
    select
        -- Identifiers
        hashkey,
        block_number,
        block_timestamp,
        tx_date                                 as failure_date,
        from_address,
        to_address,
        receipt_contract_address,

        -- Gas limits and usage
        gas                                     as gas_limit,
        receipt_gas_used,

        -- Gas cost of the failed transaction
        round(
            (receipt_gas_used * receipt_effective_gas_price) / 1e18,
            8
        )                                       as gas_cost_eth,

        round(
            {{ convert_to_usd('(receipt_gas_used * receipt_effective_gas_price) / 1e18') }},
            4
        )                                       as wasted_usd,

        -- How much of the gas limit was consumed before failure
        round(
            div0(receipt_gas_used * 100.0, gas),
            2
        )                                       as gas_used_pct,

        -- Derived: why did this transaction fail?
        case
            when div0(receipt_gas_used * 100.0, gas) >= 95
                then 'out_of_gas'
            else
                'reverted'
        end                                     as failure_reason,

        -- Derived: was this a contract interaction attempt?
        case
            when input != '0x'
            or receipt_contract_address is not null
                then true
            else false
        end                                     as is_contract_interaction,

      
        -- Raw fields passed through for context
        gas_price,
        receipt_effective_gas_price,
        input,
        transaction_type

    from source
)

select * from failed_transactions
order by block_timestamp desc