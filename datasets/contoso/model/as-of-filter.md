# Build brief: Contoso "as of" filter in Power Query

**Goal:** the Contoso data runs to 2027-12-31. On refresh, the model must only show data up to an
**as-of date**: today by default, or a fixed day for article examples, so readers see the same
numbers as the screenshots.

## Source

- Folder: `datasets/contoso/data/latest/` (Parquet, rebuilt by `generate/generate.ps1`).
- All date columns are `timestamp, tz=UTC`. Convert them with `DateTimeZone.RemoveZone`, then
  `Date.From`, and type them as `date`.

## Parameters (Manage parameters)

| Name | Type | Value | Notes |
|---|---|---|---|
| `DataFolder` | Text | path to `data\latest\` with a trailing `\` | no machine-specific paths in shared files |
| `AsOfDate` | Text | `today` | or a fixed ISO date, e.g. `2026-11-09`, for article examples |

Add a helper query `AsOf` (date) that returns `Date.From(DateTime.LocalNow())` when `AsOfDate` is
`today` (case-insensitive), and `Date.FromText(AsOfDate)` otherwise.

## Rules per table

| Table | Rule |
|---|---|
| `sales` | keep rows with `OrderDate <= AsOf`; set `DeliveryDate` to null where it is after `AsOf` (not delivered yet) |
| `orders` | keep rows with `DT <= AsOf`; same `DeliveryDate` rule |
| `orderrows` | inner join to the filtered `orders` on `OrderKey` (it has no date of its own) |
| `currencyexchange` | keep rows with `Date <= AsOf` |
| `date` | keep dates up to `Date.EndOfYear(AsOf)` (whole years for time intelligence); add `DateWithSales` = `Date <= AsOf` |
| `customer`, `product`, `store` | unchanged |

Filter right after the `Parquet.Document` step, before any other transformation.

## Done when

- Refresh with `AsOfDate = today`: the last `sales[OrderDate]` is today or the most recent day
  before it, and no fact row is dated after today.
- Refresh with `AsOfDate = 2026-11-09`: the same totals on every refresh, on any machine.
- Mark `date` as the date table. Time-intelligence measures respect `DateWithSales`, so the current
  year does not compare a partial year against a full one.
- Check numbers at 2026-11-09: 57,744 orders on or before that day (of 93,136 generated).

## Notes

- This replaces `powerquery-date-shift.m` as the default approach. Keep that file as an
  alternative; don't use both.
- Handover to `gold-layer-examples` follows the usual checklist: PBIP, no cache or local settings,
  `DataFolder` set as a parameter.
