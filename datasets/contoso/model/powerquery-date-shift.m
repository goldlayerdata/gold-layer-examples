// =====================================================================
//  OPTIONAL: keep the Contoso data "current" on every refresh
//  Shifts all fact dates so the newest order lands on (or just before) today.
//  Create these as blank queries in Power BI Desktop (Home > New Source > Blank Query).
// =====================================================================


// ---- Query 1: Folder  (text parameter) ------------------------------
// The stable hand-off path: generate.ps1 overwrites latest/ on every run.
"<repo>\datasets\contoso\data\latest\"   // replace <repo> with your clone path


// ---- Query 2: OffsetDays --------------------------------------------
// MaxDate is the last OrderDate in the generated data (see generate.ps1 EndYear).
// Rounded DOWN to whole weeks: weekday sales patterns stay intact and the
// newest order never lands in the future.
let
    MaxDate = #date(2027, 12, 31),
    Days    = Duration.Days(Date.From(DateTime.LocalNow()) - MaxDate),
    Offset  = Number.RoundDown(Days / 7) * 7
in
    Offset


// ---- Query 3: fnShiftDates (function) -------------------------------
(tbl as table, cols as list) as table =>
let
    AsDate  = Table.TransformColumnTypes(tbl, List.Transform(cols, each {_, type date})),
    Shifted = Table.TransformColumns(AsDate,
                List.Transform(cols, each {_, (d) => if d = null then null else Date.AddDays(d, OffsetDays), type date}))
in
    Shifted


// ---- Fact / dimension queries ---------------------------------------
// Sales
let  Src = Parquet.Document(File.Contents(Folder & "sales.parquet"))
in   fnShiftDates(Src, {"OrderDate", "DeliveryDate"})

// Orders
let  Src = Parquet.Document(File.Contents(Folder & "orders.parquet"))
in   fnShiftDates(Src, {"DT", "DeliveryDate"})

// Currency Exchange
let  Src = Parquet.Document(File.Contents(Folder & "currencyexchange.parquet"))
in   fnShiftDates(Src, {"Date"})

// Customer / Store: optional (StartDT, EndDT, OpenDate, CloseDate) - shift too if you
// report on customer tenure or store openings, otherwise leave as-is.


// ---- Date table -----------------------------------------------------
// Do NOT shift date.parquet: its Year / Month / Quarter / WorkingDay columns are
// precomputed and would no longer match the shifted Date. When shifting, build the
// Date table from the shifted range instead, e.g. in DAX:
//     Date = CALENDAR ( MIN ( Sales[OrderDate] ), MAX ( Sales[DeliveryDate] ) )
// (or use Bravo / a DAX date template), and mark it as a date table.
