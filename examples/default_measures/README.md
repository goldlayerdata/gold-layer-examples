# Contoso with base measures

The shared Contoso sample model, plus a set of ready-made measures: revenue, cost, margin, counts, averages, delivery and time intelligence. Use it when an article or a query needs a measure such as `[Revenue]` that already lives in the model.

- Article: [Upskilling for 2027: DAX and modeling are not enough anymore](https://goldlayerdata.com/post.html?slug=dax-and-modeling-are-not-enough)
- Try it: [Fabric app playground](https://goldlayerdata.github.io/fabric-app-playground/), which queries the same measures

## Open it

Download **`gold-layer-data-contoso-measures.pbix`** and open it in Power BI Desktop. The data is inside the file, so it opens with no setup.

To refresh it against your own copy of the data, generate the dataset first (see [datasets/contoso](../../datasets/contoso)), then in Desktop go to Transform data > Edit parameters and set **DataFolder** to the `datasets\contoso\data\latest\` folder of your clone, with the trailing backslash.

## The measures

All measures sit in one measure table, `_Measures` ("Measures" itself is a reserved name), in display folders: Sales, Profit, Counts, Averages, Delivery and Time Intelligence. Every formula, with a comment, is in [`base-measures.dax`](base-measures.dax). The one most examples use:

```dax
Revenue = SUMX ( sales, sales[Quantity] * sales[NetPrice] )
```

To see them all in Desktop, open DAX query view and pick **Quick queries > Define all measures in the model**.

## The pages

| Page | What it shows |
|---|---|
| README | What the model holds |
| Data dictionary | The tables, relationships and columns |

## Data

Contoso sample data from the [SQLBI Contoso Data Generator V2](https://github.com/sql-bi/Contoso-Data-Generator-V2) (MIT), run with our own settings. See [THIRD-PARTY-NOTICES.md](../../THIRD-PARTY-NOTICES.md).
