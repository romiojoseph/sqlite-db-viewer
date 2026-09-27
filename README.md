# SQLite DB Viewer
A desktop application built with **Flutter** to view, inspect, and compare SQLite databases. You can explore data, examine schemas or export tables as CSV.

> This is a vibe-coded project, built entirely with AI assistance. I handled the design, while the logic was AI-generated and refined through iterative prompting. Use it or fork it.


## Key Features

* **Table Explorer and Data Grid**: Browse tables, views, indexes, flexible column resizing, and pagination up to 500 rows.
* **SQL Query Runner**: Execute custom queries in separate tabs.
* **Schema Inspection and Graph**: Inspect table structures, columns, nullability, foreign keys, triggers, and ER (Entity-Relationship) diagrams.
* **Database Diff Checker**: Compare two database files side by side to detect structural changes and row-level data differences.
* **Global Search**: Search text across all tables and columns in a database at once.
* **Import and Export**: Import CSV files into tables, export individual tables/queries to CSV, or export the entire database as a zipped bundle.

## Supported File Types

* `.db`, `.sqlite`, `.sqlite3`
* `.sql` (plain SQL scripts open in temporary isolated environments)
* `.csv` (for table imports)

## Getting Started

Make sure Flutter is installed on your system.

Clone the repo then `cd` into it and then run the flutter commands. 

```bash
flutter pub get
flutter run -d windows
```