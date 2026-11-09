# Default model: Gold Layer · Contoso

The clean base model every Gold Layer example starts from: SQLBI's Contoso data (see
[`datasets/contoso`](../../datasets/contoso/README.md)) loaded into a Power BI project (PBIP) with an
**as-of date**, so the data only shows up to the day you choose.

## Open it

1. Generate the data once: `datasets\contoso\generate\generate.ps1` (100k orders, 2023 to 2027, about 20 s).
2. Open `gold-layer-data-contoso.pbip` in Power BI Desktop.
3. Set the two parameters (Transform data > Manage parameters), then refresh:

| Parameter | Value |
|---|---|
| `DataFolder` | your clone's `datasets\contoso\data\latest\` folder, with the trailing `\` |
| `AsOfDate` | `today`, or a fixed `yyyy-MM-dd` date to freeze the numbers (articles use a fixed date) |

## What's in the model

- **Facts:** `sales` (one row per order line), and `orders` + `orderrows` (header and lines). Use `sales`
  **or** `orders` + `orderrows`, not both in one visual.
- **Dimensions:** `customer`, `product`, `store`, and `date` (marked as the date table).
- **As-of rules,** applied in Power Query right after loading the Parquet files:
  - `sales`, `orders` and `currencyexchange` keep rows up to `AsOf`;
  - `orderrows` keeps the lines of the orders that remain;
  - a `DeliveryDate` after `AsOf` becomes blank (not delivered yet);
  - `date` runs to the end of the as-of year, with `DateWithSales` = TRUE up to `AsOf`.
- **No measures yet.** Each example adds the measures it teaches.

## Check your refresh

With `AsOfDate = 2026-11-09` and the default 100k build:

| Check | Value |
|---|---|
| `orders` rows | 57,744 |
| `sales` rows | 138,491 |
| Last `sales[OrderDate]` | 2026-11-09 or the last day with orders before it |

## Files

Only the PBIP text files are in git. The `.pbix`, `.pbi/cache.abf` and `localSettings.json` stay local
(see the repo's `.gitignore`). A ready-made `.pbix` is attached to the GitHub release when a post uses it.

Data: SQLBI Contoso Data Generator (MIT). See [THIRD-PARTY-NOTICES.md](../../THIRD-PARTY-NOTICES.md).
