# EikonDownloader — Copilot Instructions

## Project Overview

R package that wraps the Refinitiv/Eikon Data API using a Rust backend (via `extendr`/`rextendr`).
The package makes HTTP requests to the local Eikon/Refinitiv desktop proxy and returns data as R data frames.

**Architecture:** R → extendr FFI → Rust (reqwest + polars + tokio) → Eikon local API

---

## Dependency Status & Upgrade Plan

### Rust Dependencies (`src/rust/Cargo.toml`) — CRITICAL

| Crate | Current | Latest (approx.) | Breaking? | Notes |
|-------|---------|-------------------|-----------|-------|
| `extendr-api` | `*` (wildcard!) | `0.7.x` | **YES** | Pin to specific version. API changed significantly (List, Robj, conversions). |
| `polars` | `0.27.2` | `0.44+` | **YES** | `DataType::Utf8` → `DataType::String`; `Series::new()` signature changed; `df.iter()` → `df.get_columns()`; many other breaking changes. |
| `reqwest` | `0.11.14` | `0.12.x` | **YES** | Client builder changes, `blocking` feature API tweaks. |
| `tokio` | `1.25.0` | `1.40+` | No | Minor bumps only, safe to upgrade. |
| `chrono` | `0.4.23` | `0.4.38` | No | Safe to upgrade. |
| `serde` | `1.0.130` | `1.0.210+` | No | Safe to upgrade. |
| `serde_json` | `1.0.70` | `1.0.128+` | No | Safe to upgrade. |
| `futures` | `0.3.18` | `0.3.30+` | No | Safe to upgrade. |
| `log` | `0.4.17` | `0.4.22` | No | Safe to upgrade. |

**Priority order for Rust upgrades:**
1. Pin `extendr-api` to a real version (start with `0.7` or match what `rextendr 0.3.1` generates).
2. Upgrade `polars` — this is the largest migration. Consider whether polars is even needed (all data is converted to `Vec<String>` anyway; could just use `Vec<Vec<String>>` directly).
3. Upgrade `reqwest` to `0.12`.
4. Bump the rest (safe, non-breaking).

### R Dependencies (`DESCRIPTION`)

| Package | Current constraint | Latest | Notes |
|---------|-------------------|--------|-------|
| `httr` | any | superseded | **Replace with `httr2`** — `httr` is in maintenance mode. Only used in `ek_get_status()`. |
| `dplyr (>= 1.0.0)` | 1.0.0+ | 1.1.4 | Only used for `mutate(across(...))` to convert "null" → NA. Could replace with base R. |
| `readr` | any | 2.1.5 | Only used for `read_file()` in port detection. Could use `base::readLines()` instead. |
| `lubridate` | any | 1.9.3 | Used for date formatting. Could use `base::format()` / `as.Date()` instead. |
| `rappdirs` | any | 0.3.3 | Used for config dir lookup. Fine to keep. |
| `cli (>= 3.3.0)` | 3.3.0+ | 3.6.3 | Fine, core messaging package. |

**Possible simplifications:**
- Remove `dplyr` dep: replace `dplyr::mutate(across(...))` with `lapply(df, function(x) replace(x, x == "null", NA))`.
- Remove `readr` dep: replace `readr::read_file()` with `readLines()` + `paste(collapse="")`.
- Remove `lubridate` dep: replace `format_ISO8601()` with `format(x, "%Y-%m-%d")` and `is.Date()` with `inherits(x, "Date")`.
- Replace `httr` with `httr2` or even base `curl`.

### Tooling / Config

| Item | Current | Latest | Notes |
|------|---------|--------|-------|
| `RoxygenNote` | 7.2.3 | 7.3.2 | Regenerate docs with latest roxygen2. |
| `Config/rextendr/version` | 0.2.0.9000 | 0.3.1 | Upgrade rextendr; re-run `rextendr::document()` to regenerate wrappers. |
| GH Actions `actions/checkout` | v3 | v4 | Update workflow. |
| GH Actions `actions/upload-artifact` | v3 | v4 | Update workflow. |

---

## Known Code Issues (Rust)

1. **`DataType::Utf8`** in `lib.rs:119` — renamed to `DataType::String` in polars ≥0.34.
2. **`Series::new(name, values)`** — newer polars uses `Column::new()` or `Series::new(name.into(), values)` with `PlSmallStr`.
3. **`df.iter()`** in `lib.rs:128` — replaced by `df.get_columns()` in recent polars.
4. **`List::into_hashmap()`** — extendr-api may have changed this method signature.
5. **`PolarsError::NoData(...)`** — error variant removed/renamed in newer polars.
6. **`s.f64()` / `s.utf8()`** — accessor methods renamed in newer polars (`s.str()` for string).
7. **`DataFrame::new(vec)`** — may now require `Column` instead of `Series`.

## Known Code Issues (R)

1. `dplyr::across(where(is.character), ...)` — `where` is from `tidyselect`, not imported explicitly.
2. `.pkgglobalenv$ek$base_url` referenced in `ek_get_status()` but never defined in `.onLoad`.

---

## Recommended Upgrade Strategy

### Option A: Minimal (get it compiling again)
1. Pin `extendr-api = "0.6"` (last version before major 0.7 changes).
2. Keep `polars = "0.27"` (or bump to `0.32` with minimal fixes).
3. Keep `reqwest = "0.11"`.
4. Fix the missing `base_url` in `.onLoad`.
5. Update GitHub Actions to v4.

### Option B: Full modernization
1. Upgrade `rextendr` to 0.3.1, regenerate all boilerplate.
2. Upgrade `extendr-api` to `0.7`.
3. **Remove `polars` entirely** — the crate is only used to build a `DataFrame` from `Vec<String>` columns, which can be done directly with extendr's `List` (already the output type). This eliminates the biggest pain point.
4. Upgrade `reqwest` to `0.12`.
5. Replace `httr` → `httr2`, remove `dplyr`/`readr`/`lubridate` in favor of base R.
6. Bump minimum R version to 4.1+ (for native pipe and lambda syntax if desired).

### Option C: Rewrite in pure R
Since the Rust code only does HTTP requests + JSON parsing + basic reshaping, consider whether `httr2` + `jsonlite` in pure R would be simpler to maintain. The async batching could use `curl::multi_run()`.

---

## Build & Development

```bash
# Install rextendr (needed to rebuild Rust wrappers)
Rscript -e 'install.packages("rextendr")'

# Regenerate Rust wrappers after extendr-api changes
Rscript -e 'rextendr::document()'

# Build package
R CMD build .
R CMD INSTALL .

# Run tests
Rscript -e 'testthat::test_local()'

# Check package
R CMD check --as-cran EikonDownloader_*.tar.gz
```

## File Map

```
R/
  API_connection.R   — Port detection, API key management, status checks
  datagrid.R         — get_datagrid() wrapper around Rust
  timeseries.R       — get_timeseries() wrapper around Rust
  extendr-wrappers.R — Auto-generated FFI glue (DO NOT EDIT)
  zzz.R             — Package environment setup

src/rust/
  src/lib.rs         — extendr entry points, polars→R conversion
  src/connection.rs  — HTTP client, handshake, async request handler
  src/datagrid.rs    — Datagrid payload assembly & JSON→DataFrame
  src/timeseries.rs  — TimeSeries payload assembly & JSON→DataFrame
  src/utils.rs       — Error types, field builder, vstack helper
```
