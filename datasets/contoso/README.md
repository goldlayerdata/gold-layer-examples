# Contoso

Retail sales data for Power BI and Fabric demos, built with the open-source
**[SQLBI Contoso Data Generator V2](https://github.com/sql-bi/Contoso-Data-Generator-V2)**
(MIT, © SQLBI). Full generator documentation: https://docs.sqlbi.com/contoso-data-generator/

Why generate it instead of downloading SQLBI's
[ready-made sets](https://github.com/sql-bi/Contoso-Data-Generator-V2-Data)? Those stop at
2024-04-20. Running the generator ourselves gives a date range that reaches into the future, and
moving it forward is one parameter.

## Rebuild the data

```powershell
.\generate\generate.ps1                                  # 1M orders, Parquet, 2018-01-01 -> 2027-12-31
.\generate\generate.ps1 -EndYear 2030                    # roll the window forward
.\generate\generate.ps1 -Orders 10000000 -CustomerPct 0.8
.\generate\generate.ps1 -Format DELTATABLE               # for a Fabric Lakehouse
.\generate\generate.ps1 -Archive                         # also keep a dated snapshot in data/runs/
```

Output goes to `data/latest/`. That path never changes, so the model just refreshes after a
rebuild. The script builds into `data/_staging/` first, so a failed run never leaves `latest/`
half-written. `data/latest/_manifest.json` records the parameters, date range, row counts and files.

## Tables (default 1M build)

| Table | Rows | Notes |
|---|---|---|
| sales | 2,376,336 | fact, one row per order line. Flat star: use this **or** orders + orderrows |
| orders | 991,155 | fact header (order level) |
| orderrows | 2,376,336 | fact lines, child of orders |
| customer | 104,990 | synthetic people across AU, CA, DE, FR, IT, NL, UK and US |
| product | 2,517 | from `data.xlsx` |
| store | 74 | from `data.xlsx`. Open/close dates stop in 2019 (template data) |
| date | 4,018 | 2018-01-01 -> 2028-12-31, one year past the last order to cover deliveries |
| currencyexchange | 100,450 | daily rates, unrelated table used by conversion measures |

## Relationships

- `sales` → `customer`, `product`, `store` on `CustomerKey`, `ProductKey`, `StoreKey`
- `sales[OrderDate]` → `date[Date]`
- `orderrows` → `orders` on `OrderKey`; `orders` → `customer`, `store`; `orders[DT]` → `date[Date]`
- Rules: `DeliveryDate >= OrderDate`. Prices are in USD, and `CurrencyCode` + `ExchangeRate` give the order's local currency.

## Things to know

- **Future exchange rates are made up.** The cached European Central Bank rates end at a fixed date,
  and later days are filled by mirroring past values forward.
- **Demand spikes are on fixed dates.** `OneTimeSpikes` in `config.json` sit in 2016, 2018 and a
  2020–21 dip. Edit them if you move the window far.
- **Reproducibility:** the engine seeds itself, so the same inputs give the same orders and rows,
  but a few attributes (the online flag) vary slightly between runs. See `generate/seed.txt`.
- **Dates that stay current:** `model/powerquery-date-shift.m` shifts every date on refresh so the
  last order lands on today. When you use it, build the date table from the shifted range instead
  of importing `date.parquet`, whose precomputed year and month columns would no longer match.

## Engine setup (one-off, not in git)

```text
<repo>/.engine/contoso/
├── DatabaseGenerator.exe   from DatabaseGenerator.winx64.zip, release 2.0.1:
│                           https://github.com/sql-bi/Contoso-Data-Generator-V2/releases
└── cache/                  ~480 MB of static files, downloaded on the first run
```

To keep the engine somewhere else, set `CONTOSO_GEN_HOME` to its folder.

If the first run keeps failing with GitHub `504` errors, fill the cache with the GitHub CLI instead:

```bash
cd .engine/contoso/cache
gh release download static-files -R sql-bi/Contoso-Data-Generator-V2-Data --skip-existing
```

## Files

| Path | What |
|---|---|
| `generate/generate.ps1` | builds `data/latest/` and writes `_manifest.json` |
| `generate/config.json` | generator settings: SQLBI release defaults, with the date and size keys set to the script defaults |
| `generate/data.xlsx` | product, category and store template data (SQLBI) |
| `generate/seed.txt` | how reproducibility works for this engine |
| `model/powerquery-date-shift.m` | optional Power Query that keeps dates current on refresh |
