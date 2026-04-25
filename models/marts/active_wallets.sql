{{config(materialized='table')}}

with transfers as (
    select 
        *
    from {{ref('int_eth_transfers')}}
    where is_successful = true
    and transfer_type = 'eth_transfer'
),

whales as (
    select 
        distinct from_address as wallet_address
    from {{ref('whale_alert')}}
),


-- sender perspective: everytime this wallet sent ETH
senders as (
    select
       from_address as wallet_address,  
       'sender' as role,
       hashkey,
       block_timestamp,
       to_address as counterparty,
       value_eth,
       value_usd  
    from transfers
),

-- receiver perspective: everytime this wallet received ETH
receivers as (
    select
       to_address as wallet_address,  
       'receiver' as role,
       hashkey,
       block_timestamp,
       from_address as counterparty,
       value_eth,
       value_usd  
    from transfers
    where to_address is not null
),

all_activity as (
    select * from senders
    union all
    select * from receivers
),

-- aggregate to one row per wallet
wallet_summary as (
    select
      wallet_address,

        -- transaction counts by role
        sum(case when role = 'sender' then 1 else 0 end) as send_count,
        sum(case when role = 'receiver' then 1 else 0 end) as receive_count,
        count(*) as total_tx_count,
        -- eth volumne by role
        round(sum(case when role = 'sender' then value_eth else 0 end) ,6) as total_eth_sent,
        round(sum(case when role = 'receiver' then value_eth else 0 end) ,6) as total_eth_received,
        -- usd volumne by role
        round(sum(case when role = 'sender' then value_usd else 0 end) ,2) as total_usd_sent,
        round(sum(case when role = 'receiver' then value_usd else 0 end) ,2) as total_usd_received,
        -- wallet lifespan
        min(block_timestamp) as first_seen,
        max(block_timestamp) as last_seen,
        -- breadth of activity
        count(distinct counterparty) as unique_counterparties   
    from all_activity
    group by wallet_address
),

-- join whale flag and derive wallet type
final as (
    select
        ws.*,

        -- Derived: is this wallet a whale?
        case 
            when w.wallet_address is not null then true
            else false
        end as is_whale,
        -- Derived: behavioral classification
        case 
            when w.wallet_address is not null then 'whale'
            when ws.total_tx_count > 100 then 'high_frequency'
            when ws.total_eth_received > ws.total_eth_sent * 2 then 'accumulator'
            when ws.total_eth_sent > ws.total_eth_received * 2 then 'distributor'
            else 'regular'
        end as wallet_type

    from wallet_summary ws
    left join whales w on ws.wallet_address = w.wallet_address
)

select * from final