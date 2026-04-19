{{config(materialized='view')}}

with source as (
    select * from {{ ref('int_eth_transfers')}}
),

contract_activity as (
    select 
        -- identifiers for joins
        hashkey,
        block_number,
        block_timestamp,
        tx_date,
        from_address,
        to_address,
        receipt_contract_address,

        -- Derived: single unified contract address column
        coalesce(receipt_contract_address, to_address) as contract_address,

        -- passed through from int_eth_transfers
        transfer_type,
        value_eth,
        value_usd,
        value_wei,
        is_successful,

        -- Derived: cleaner boolean for contract creation specifically
        case
            when transfer_type = 'contract_creation' then true
            else false
        end as is_contract_creation,

        -- Derived: length of input data as a proxy for call complexity
        length(input) as input_data_length,

        -- passed through, renamed for clarity in contracr context
        has_value as has_eth_value
    from source
    -- core filter: only keeps rows where contract code was executed
    where transfer_type IN ('contract_creation', 'contract_interaction')
)
select * from contract_activity