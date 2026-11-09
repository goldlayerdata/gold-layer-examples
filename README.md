# Gold Layer examples

Worked Power BI and Fabric examples from [Gold Layer](https://goldlayerdata.com/), built on
open datasets so you can rebuild every one of them yourself.

Each post or short on the site that shows a technique on real-looking data points to an
`examples/<topic>/` folder here, with the report page, the DAX and the screenshots.

## Datasets

| Dataset | What | Source | Licence |
|---|---|---|---|
| [contoso](datasets/contoso/) | Retail sales: orders, customers, products, stores, multi-currency. 1M orders, 2018–2027 by default | [SQLBI Contoso Data Generator V2](https://github.com/sql-bi/Contoso-Data-Generator-V2) | MIT |

The data files are not stored in git. Each dataset has a `generate/` folder that rebuilds them
locally in under a minute. Credits and licence texts: [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Layout

```text
datasets/<name>/
├── README.md        source, tables, relationships, how to rebuild
├── generate/        the recipe: script + settings (tracked)
├── data/latest/     generated files (git-ignored) + _manifest.json (tracked)
└── model/           the shared semantic model every example uses
examples/<topic>/    one folder per post: report page, DAX, screenshots
.engine/             local generator binaries and caches (git-ignored)
```

## Quick start (Contoso)

```powershell
# one-off: put the generator in .engine/contoso/ (see datasets/contoso/README.md)
.\datasets\contoso\generate\generate.ps1            # 1M orders, Parquet, 2018-01-01 to 2027-12-31
.\datasets\contoso\generate\generate.ps1 -EndYear 2030
```
