# ETH — Ethereum Analytics dbt Project

> A dbt (data build tool) project for transforming and modelling Ethereum blockchain data.

---

## 📌 Overview

This project uses **dbt** to build a clean, tested, and documented analytics layer on top of raw Ethereum on-chain data. It follows the standard dbt project structure and is designed to be modular and easy to extend as the project grows.

**Data source:** Ethereum blockchain (on-chain data)  
**Transformation tool:** dbt  
**Target warehouse:** Snowflake 

---

## 🗂️ Project Structure

```
ETH/
├── analyses/       # Ad-hoc analytical queries (not materialized)
├── macros/         # Reusable Jinja2 / SQL macros
├── models/
│   └── stg/    
├── seeds/          # Static CSV data loaded into the warehouse
├── snapshots/      # Type-2 SCD snapshots for slowly changing dimensions
├── tests/          # Custom data tests
├── dbt_project.yml # Project configuration
└── README.md
```

---

## ⚙️ Setup & Installation

### Prerequisites

- Python 3.12+
- dbt Core
- Access to your target data warehouse

### Install dbt

```bash
pip install dbt-core dbt-snowflake 
```

### Clone the repo

```bash
git clone https://github.com/TemiBytes/ETH.git
cd ETH
```

### Configure your profile

dbt uses a `profiles.yml` file (stored in `~/.dbt/`) to connect to your warehouse. Create one for this project:

```yaml
eth:
  target: dev
  outputs:
    dev:
      type: <your_adapter>        # e.g. bigquery, snowflake, duckdb
      # add your warehouse-specific connection details here
```

Refer to the [dbt profiles documentation](https://docs.getdbt.com/docs/core/connect-data-platform/profiles.yml) for adapter-specific settings.

---

## 🚀 Running the Project

```bash
# Install dbt package dependencies (if any)
dbt deps

# Run all models
dbt run

# Run tests
dbt test

# Generate and serve documentation
dbt docs generate
dbt docs serve

# Seed static data
dbt seed

# Run snapshots
dbt snapshot
```

---

## 🧱 Models

> ⚠️ _This section will be expanded as models are built out._

Models are organized by layer following dbt best practices:

| Layer | Description |
|-------|-------------|
| `staging` | Raw source data cleaned and typed _(coming soon)_ |
| `intermediate` | Business logic and joins _(coming soon)_ |
| `marts` | Final analytics-ready tables / views _(coming soon)_ |

All models in `models/example/` are currently materialized as **views** (default config).

---

## 🧪 Testing

This project uses dbt's built-in testing framework. Tests are defined in `.yml` files alongside models.

```bash
dbt test
```

Custom tests live in the `tests/` directory.

---

## 🌱 Seeds

Static reference data (CSV files) are loaded via `dbt seed`. Seed files live in the `seeds/` directory.

---

## 📸 Snapshots

Slowly changing dimension (SCD Type 2) logic is captured in the `snapshots/` directory. Run with:

```bash
dbt snapshot
```

---

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/docs/introduction)
- [dbt Discourse](https://discourse.getdbt.com/)
- [dbt Community Slack](https://community.getdbt.com/)
- [dbt Blog](https://blog.getdbt.com/)
- [Ethereum JSON-RPC API Docs](https://ethereum.org/en/developers/docs/apis/json-rpc/)

---

## 🛣️ Roadmap

- [ ] Add staging models for raw Ethereum data
- [ ] Add intermediate models for transaction and block analytics
- [ ] Build marts for whale_alert, gas usage, and more
- [ ] Add schema tests and source freshness checks
- [ ] Set up CI/CD with GitHub Actions

---

## 👤 Author

**TemiBytes** — [GitHub](https://github.com/TemiBytes)

---
