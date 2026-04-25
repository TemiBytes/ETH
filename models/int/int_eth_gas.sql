{{config(materialized='view')}}

with source as (
    select * from {{ ref('stg_eth')}}
),

gas_enriched as (
    select
        -- identifiers for joins
        hashkey,
        block_number,
        block_timestamp,
        tx_date,
        from_address,

        -- raw gas fields for reference
        gas as gas_limit,
        gas_price,
        receipt_gas_used,
        receipt_effective_gas_price,
        max_fee_per_gas,
        max_priority_fee_per_gas,

        -- derived: actual cost of this transaction in ETH, calculated as gas used * effective gas price, converted from wei to eth
        div0(receipt_gas_used * receipt_effective_gas_price, 1e18) as gas_cost_eth,


        -- Derived: how much of the gas limit was actually consumed
        div0(
            receipt_gas_used * 100.0,
            gas
        )                               as gas_utilization_pct,

        -- Derived: was this transaction using the EIP-1559 fee model?
        case
            when max_fee_per_gas is not null
            and max_priority_fee_per_gas is not null
                then true
            else false
        end                             as is_eip1559,

        -- Derived: base fee per gas (EIP-1559 only — null for legacy txns)
        case
            when max_fee_per_gas is not null
            and max_priority_fee_per_gas is not null
                then receipt_effective_gas_price - max_priority_fee_per_gas
            else null
        end                             as base_fee_per_gas

    from source
)
select 
    hashkey,
    block_number,
    block_timestamp,
    tx_date,
    from_address,
    gas_limit,
    gas_price,
    receipt_gas_used,
    receipt_effective_gas_price,
    max_fee_per_gas,
    max_priority_fee_per_gas,
    gas_cost_eth,
    -- Derived: gas cost converted to USD using the most recent ETH/USD price from the eth_usd_max table
    {{ convert_to_usd('gas_cost_eth') }} as gas_cost_usd,
    gas_utilization_pct,
    is_eip1559,
    base_fee_per_gas
from gas_enriched

