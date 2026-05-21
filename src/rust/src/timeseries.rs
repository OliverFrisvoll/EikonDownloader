use crate::connection::{Connection, Direction};
use crate::utils::{clean_string, EkError, EkResults};
use chrono::prelude::*;
use serde_json::{json, Value};

pub enum Interval {
    Minute,
    Hour,
    Daily,
    Weekly,
    Monthly,
    Quarterly,
    Yearly,
}

impl Interval {
    fn as_str(&self) -> &'static str {
        match self {
            Interval::Minute => "minute",
            Interval::Hour => "hour",
            Interval::Daily => "daily",
            Interval::Weekly => "weekly",
            Interval::Monthly => "monthly",
            Interval::Quarterly => "quarterly",
            Interval::Yearly => "yearly",
        }
    }
}

pub struct TimeSeries {
    connection: Connection,
}

impl TimeSeries {
    pub fn new(c: Connection) -> Self {
        Self { connection: c }
    }

    pub fn get_timeseries(
        &self,
        rics: Vec<String>,
        fields: Vec<String>,
        frq: Interval,
        s_date: NaiveDateTime,
        e_date: NaiveDateTime,
    ) -> EkResults {
        let direction = Direction::TimeSeries;
        let payloads = build_payloads(rics, fields, s_date, e_date, frq);
        let res = match self.connection.send_request_async_handler(payloads, direction) {
            Ok(r) => r,
            Err(e) => return EkResults::Err(e),
        };
        if res.is_empty() {
            return EkResults::Err(EkError::NoData("No data returned from Refinitiv".to_string()));
        }

        // Collect all response chunks into columnar data
        let mut all_names: Vec<String> = Vec::new();
        let mut all_columns: Vec<Vec<Option<String>>> = Vec::new();

        for response in res {
            match to_columns(response) {
                Err(e) => return EkResults::Err(e),
                Ok(None) => {}
                Ok(Some((names, columns))) => {
                    if all_names.is_empty() {
                        all_names = names;
                        all_columns = columns;
                    } else {
                        // Append rows (same column structure assumed after alignment)
                        let aligned = align_columns(&all_names, &names, columns);
                        for (i, col) in aligned.into_iter().enumerate() {
                            all_columns[i].extend(col);
                        }
                    }
                }
            }
        }

        if all_names.is_empty() {
            return EkResults::Err(EkError::NoData("No valid timeseries data".to_string()));
        }

        EkResults::Columns {
            names: all_names,
            columns: all_columns,
        }
    }
}

/// Align incoming columns to the target header order, filling missing with None
fn align_columns(
    target_names: &[String],
    source_names: &[String],
    source_columns: Vec<Vec<Option<String>>>,
) -> Vec<Vec<Option<String>>> {
    let n_rows = source_columns.first().map(|c| c.len()).unwrap_or(0);
    target_names
        .iter()
        .map(|name| {
            if let Some(idx) = source_names.iter().position(|n| n == name) {
                source_columns[idx].clone()
            } else {
                vec![None; n_rows]
            }
        })
        .collect()
}

fn build_payloads(
    rics: Vec<String>,
    fields: Vec<String>,
    s_date: NaiveDateTime,
    e_date: NaiveDateTime,
    frq: Interval,
) -> Vec<Value> {
    let trading_days: usize = 252;
    let max_rows: usize = 3000;
    let max_companies: usize = 300;
    let period = e_date.signed_duration_since(s_date);
    let rows_pr = match frq {
        Interval::Minute => (period.num_minutes() as f32 / 2f32).ceil() as usize,
        Interval::Hour => (period.num_hours() as f32 / 2f32).ceil() as usize,
        Interval::Daily => {
            ((trading_days as f32 / 365f32) * period.num_days() as f32).ceil() as usize
        }
        Interval::Weekly => (period.num_weeks() as f32).ceil() as usize,
        Interval::Monthly => ((period.num_days() as f32 / 365f32) * 12f32).ceil() as usize,
        Interval::Quarterly => ((period.num_days() as f32 / 365f32) * 4f32).ceil() as usize,
        Interval::Yearly => (period.num_days() as f32 / 365f32).ceil() as usize,
    };

    let ric_group_size = if rics.len() > max_companies {
        max_companies
    } else {
        rics.len()
    };

    let time_groups =
        ((rows_pr as f32 * ric_group_size as f32) / max_rows as f32).ceil() as usize;
    let time_groups = create_intervals(time_groups.max(1), s_date, e_date);

    let mut payloads: Vec<Value> = Vec::new();
    for ric_group in rics.chunks(ric_group_size) {
        for (sd, ed) in time_groups.iter() {
            payloads.push(assemble_payload(
                ric_group.to_vec(),
                &fields,
                frq.as_str(),
                sd,
                ed,
            ));
        }
    }
    payloads
}

fn assemble_payload(
    rics: Vec<String>,
    fields: &[String],
    frq: &str,
    s_date: &NaiveDateTime,
    e_date: &NaiveDateTime,
) -> Value {
    json!({
        "rics": rics,
        "fields": fields,
        "interval": frq,
        "startdate": s_date.to_string(),
        "enddate": e_date.to_string()
    })
}

fn create_intervals(
    groups: usize,
    s_date: NaiveDateTime,
    e_date: NaiveDateTime,
) -> Vec<(NaiveDateTime, NaiveDateTime)> {
    let mut intervals: Vec<(NaiveDateTime, NaiveDateTime)> = Vec::with_capacity(groups);
    let dur = e_date.signed_duration_since(s_date) / groups as i32;
    let mut start = s_date;
    for _ in 0..groups {
        let end = if start + dur > e_date {
            e_date
        } else {
            start + dur
        };
        intervals.push((start, end));
        start = end;
    }
    intervals
}

fn fetch_headers(json_like: &Value) -> Option<Vec<String>> {
    if json_like["statusCode"] != "Normal" {
        return None;
    }
    let fields = json_like["fields"].as_array()?;
    let mut names: Vec<String> = fields
        .iter()
        .map(|v| clean_string(v["name"].to_string()))
        .collect();
    names.push(String::from("RIC"));
    Some(names)
}

fn to_columns(
    json_like: Value,
) -> Result<Option<(Vec<String>, Vec<Vec<Option<String>>>)>, EkError> {
    let ts_data = match json_like["timeseriesData"].as_array() {
        None => {
            return Err(EkError::Error(
                "Could not parse timeseriesData as array".to_string(),
            ))
        }
        Some(r) => r,
    };

    // Find headers from first valid response
    let mut headers: Vec<String> = Vec::new();
    for request in ts_data {
        if let Some(r) = fetch_headers(request) {
            headers = r;
            break;
        }
    }

    if headers.is_empty() {
        return Ok(None);
    }

    // Build columns
    let mut columns: Vec<Vec<Option<String>>> = vec![Vec::new(); headers.len()];

    for ric in ts_data {
        if ric["statusCode"] != "Normal" {
            continue;
        }
        let data_points = match ric["dataPoints"].as_array() {
            Some(r) => r,
            None => continue,
        };
        let ric_name = clean_string(ric["ric"].to_string());

        for row in data_points {
            for (i, col) in columns.iter_mut().enumerate() {
                if headers[i] == "RIC" {
                    col.push(Some(ric_name.clone()));
                } else {
                    let val = &row[i];
                    if val.is_null() {
                        col.push(None);
                    } else {
                        col.push(Some(clean_string(val.to_string())));
                    }
                }
            }
        }
    }

    Ok(Some((headers, columns)))
}
