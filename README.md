# Ethereum Analytics Pipeline

A production-ready ELT pipeline built with dbt Core and Snowflake on 
real Ethereum transaction data from the AWS Public Blockchain Dataset.

Raw Parquet files land in Snowflake as semi-structured VARIANT payloads. 
dbt transforms them through a three-layer architecture into six 
analytical mart tables — all tested, documented, and deployed via 
a GitHub Actions CI/CD pipeline.

---

## What This Pipeline Produces

| Mart | Description |
|---|---|
| `whale_alert` | Large ETH transfers classified by tier and ranked daily by USD value |
| `gas_price_trends` | Daily gas fee analytics split by EIP-1559 vs legacy fee model |
| `active_wallets` | Behavioural profiles for every wallet in the dataset |
| `contract_leaderboard` | Smart contracts ranked by interaction count and ETH received |
| `block_activity` | Network throughput and congestion metrics per block |
| `failed_tx_analysis` | Failed transactions with failure reason and gas cost wasted |

---

## Architecture
```
Source (S3)
└── eth_transactions_raw        [Snowflake raw table — single VARIANT column]
    └── stg_eth                 [Staging — flatten, cast, deduplicate, fix nulls]
        ├── int_eth_gas                  [Gas cost enrichment + EIP-1559 flags]
        ├── int_eth_transfers            [Value movement + transfer type classification]
        └── int_eth_contract_activity   [Contract interactions isolated]
            ├── whale_alert
            ├── gas_price_trends
            ├── active_wallets
            └── contract_leaderboard

        [Direct from staging]
        ├── block_activity
        └── failed_tx_analysis
```

---

## Tech Stack

- **dbt Core** — transformation framework
- **Snowflake** — data warehouse
- **AWS S3** — public blockchain data source
- **GitHub Actions** — CI/CD pipeline

---

## Data Source

The raw data comes from the [AWS Public Blockchain Dataset](https://registry.opendata.aws/aws-public-blockchain/), 
a publicly available S3 bucket maintained by AWS. No credentials required.

Transactions are loaded daily using a Snowflake scripted procedure that 
pulls the previous day's high-value transactions (value > 10 ETH) from 
the S3 stage into the raw landing table.

---

## Project Structure
```
models/
├── staging/
│   ├── _sources.yml
│   ├── _stg__models.yml
│   └── stg_eth_transactions.sql
├── intermediate/
│   ├── _int__models.yml
│   ├── int_eth_gas.sql
│   ├── int_eth_transfers.sql
│   └── int_eth_contract_activity.sql
└── marts/
    ├── _marts__models.yml
    ├── whale_alert.sql
    ├── gas_price_trends.sql
    ├── active_wallets.sql
    ├── contract_leaderboard.sql
    ├── block_activity.sql
    └── failed_tx_analysis.sql

macros/
└── convert_to_usd.sql

seeds/
└── eth_usd_max.csv
```

---

## CI/CD Pipeline

Every pull request triggers a GitHub Actions workflow that:

1. Spins up a fresh Ubuntu environment
2. Installs dbt Core and the Snowflake adapter
3. Authenticates to Snowflake using RSA key pair authentication
4. Runs `dbt build` against the dev schema — models and tests in DAG order
5. Fails the PR if any model or test fails

Branch-based target switching ensures dev branches always run against 
the dev schema. Only code merged to master touches the production schema.

---

## Running This Project

**Prerequisites**
- dbt Core installed (`pip install dbt-core dbt-snowflake`)
- A Snowflake account with the raw table set up (see `eth.sql` in the repo)
- RSA key pair configured in your `profiles.yml`

**Setup**
```bash
# Install dependencies
dbt deps

# Test your connection
dbt debug

# Run the full pipeline
dbt build -s stg_eth_transactions+
```

---

## Related Article

Full walkthrough of how this pipeline was designed and built:

[From raw blockchain payloads to whale alerts: building an Ethereum 
analytics pipeline with dbt and Snowflake](https://medium.com/@temi_akins/from-raw-blockchain-payloads-to-whale-alerts-building-an-ethereum-analytics-pipeline-with-dbt-and-7bcaf455f554)

*(link to be added once published)*

---

## Author

**Temidayo**
[LinkedIn](https://www.linkedin.com/in/temi-akins/) · [Medium](https://medium.com/@temi_akins)
