with source as (
    select 
        payload
    from {{ source('eth', 'eth_transactions_raw')}}
),
flattened as (
    select 
        -- Block-related fields
        payload:block_hash::string as block_hash, -- unique cryptographic identifier of the block containing the transaction this transaction
        payload:block_number::integer as block_number,
        payload:block_timestamp::timestamp as block_timestamp,
        payload:date::date as tx_date,
        
        -- Transaction identifiers
        payload:hash::string as hashkey, -- unique cryptographic identifier of the transaction
        payload:transaction_index::integer as transaction_index,
        payload:transaction_type::integer as transaction_type,
        
        -- Addresses
        nullif(payload:from_address::string, '') as from_address,
        nullif(payload:to_address::string, '') as to_address,
        nullif(payload:receipt_contract_address::string, '') as receipt_contract_address,
        
        -- Gas-related fields
        payload:gas::integer as gas,
        payload:gas_price::integer as gas_price,
        payload:max_fee_per_gas::integer as max_fee_per_gas,
        payload:max_priority_fee_per_gas::integer as max_priority_fee_per_gas,
        payload:receipt_cumulative_gas_used::integer as receipt_cumulative_gas_used,
        payload:receipt_effective_gas_price::integer as receipt_effective_gas_price,
        payload:receipt_gas_used::integer as receipt_gas_used,
        
        -- Transaction details
        payload:nonce::integer as nonce,
        payload:value::number(38, 0) as value_wei,
        payload:input::string as input,
        payload:receipt_status::integer as receipt_status,
        
        -- Metadata
        payload:last_modified::timestamp as last_modified
    from source
)
select * from flattened qualify row_number() over (partition by hashkey order by last_modified desc) = 1