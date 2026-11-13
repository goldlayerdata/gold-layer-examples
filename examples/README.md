# Examples

One folder per technique, named after the post or short it belongs to (kebab-case). Each one ships as a
single PBIX with its data inside: download it and open it in Power BI Desktop, no setup.

| Example | What it shows | Post |
|---|---|---|
| [default](default/) | The shared Contoso model every example starts from: tables, relationships, data dictionary | |
| [pareto](pareto/) | A Pareto chart two ways (visual calculations and DAX), shaded zones, a cutoff slicer, the `RUNNINGSUM` trap | [Pareto in Power BI](https://goldlayerdata.com/post.html?slug=pareto-in-power-bi-dax-vs-visual-calculations) |

```text
examples/<topic>/
├── <name>.pbix      the report with its data, ready to open
├── README.md        what it shows, the numbers, link to the post and the short
├── *.dax            the formulas, ready to paste
└── img/             screenshots and SVGs used on the site
```
