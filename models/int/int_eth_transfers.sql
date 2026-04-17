{{ config(materialized='view') }}
with source as (
    select * from {{ ref('stg_eth')}}
),

transfers_enriched as (
    select 
        -- identifiers for joins
        hashkey,
        block_number,
        block_timestamp,
        tx_date,
        from_address,
        to_address,
        receipt_contract_address,
        -- raw value (kept for reference)
        value_wei,
        -- derived: value converted from wei to eth
        value_wei / 1e18 as value_eth,
        -- derived: value converted from wei to usd using the most recent eth/usd price
        {{ convert_to_usd('value_wei / 1e18') }} as value_usd,
        -- derived: what kind of transfer is this ?
        case
            when input ='0x' then 'eth_transfer'
            when receipt_contract_address is not null then 'contract_creation'
            else 'contract_interaction'
        end as transfer_type,
        -- derived: cleaner boolean version of receipt_status
        case
            when receipt_status = 1 then true
            when receipt_status = 0 then false
        end as is_successful,
        -- derived: did any ETH actually move ?
        case 
            when value_wei > 0 then true
            else false
        end as has_value
    from source
)

select * from transfers_enriched