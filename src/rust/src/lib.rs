#![allow(non_snake_case)]

use crate::connection::Connection;
use crate::datagrid::Datagrid;
use crate::timeseries::{Interval, TimeSeries};
use crate::utils::{EkError, EkResults, field_builder, Fields};
use chrono::prelude::*;
use extendr_api::prelude::*;
use std::collections::HashMap;

mod connection;
mod datagrid;
mod timeseries;
mod utils;

#[extendr]
fn rust_get_dg(
    instruments: Vec<String>,
    fields: Vec<String>,
    param: List,
    settings: List,
    api: String,
    port: i32,
) -> Robj {
    let con = Connection::new(api, "127.0.0.1".to_string(), port as i16);
    let dg = Datagrid::new(con);
    let params = list_to_hm_string(&param);
    let settings_map = list_to_hm_bool(&settings);
    let fields_json = field_builder(Fields::NoParams(fields));

    match dg.get_datagrid(instruments, fields_json, Some(params), settings_map) {
        EkResults::Columns { names, columns } => columns_to_r_list(&names, columns),
        EkResults::Raw(r) => value_strings(r).into_robj(),
        EkResults::Err(e) => vec!["Error".to_string(), e.to_string()].into_robj(),
    }
}

#[extendr]
fn rust_get_ts(
    rics: Vec<String>,
    fields: Vec<String>,
    Frq: &str,
    Start_Date: &str,
    End_Date: &str,
    api: String,
    port: i32,
) -> Robj {
    let con = Connection::new(api, "127.0.0.1".to_string(), port as i16);
    let ts = TimeSeries::new(con);

    let s_date = match NaiveDateTime::parse_from_str(Start_Date, "%FT%T") {
        Ok(d) => d,
        Err(e) => return vec!["Error".to_string(), format!("Cannot parse start_date: {e}")].into_robj(),
    };

    let e_date = match NaiveDateTime::parse_from_str(End_Date, "%FT%T") {
        Ok(d) => d,
        Err(e) => return vec!["Error".to_string(), format!("Cannot parse end_date: {e}")].into_robj(),
    };

    let interval = match Frq {
        "minute" => Interval::Minute,
        "hour" => Interval::Hour,
        "daily" => Interval::Daily,
        "weekly" => Interval::Weekly,
        "monthly" => Interval::Monthly,
        "quarterly" => Interval::Quarterly,
        "yearly" => Interval::Yearly,
        _ => Interval::Daily,
    };

    match ts.get_timeseries(rics, fields, interval, s_date, e_date) {
        EkResults::Columns { names, columns } => columns_to_r_list(&names, columns),
        EkResults::Raw(r) => value_strings(r).into_robj(),
        EkResults::Err(e) => vec!["Error".to_string(), e.to_string()].into_robj(),
    }
}

fn list_to_hm_string(l: &List) -> HashMap<String, String> {
    let mut params: HashMap<String, String> = HashMap::new();
    for (key, value) in l.iter() {
        if let Some(s) = value.as_str() {
            params.insert(key.to_string(), s.to_string());
        }
    }
    params
}

fn list_to_hm_bool(l: &List) -> HashMap<String, bool> {
    let mut params: HashMap<String, bool> = HashMap::new();
    for (key, value) in l.iter() {
        if let Some(b) = value.as_bool() {
            params.insert(key.to_string(), b);
        }
    }
    params
}

/// Convert columnar data into a named R list (data.frame-compatible)
fn columns_to_r_list(names: &[String], columns: Vec<Vec<Option<String>>>) -> Robj {
    let values: Vec<Robj> = columns
        .into_iter()
        .map(|col| {
            let strs: Strings = col
                .into_iter()
                .map(|v| match v {
                    Some(s) => Rstr::from(s),
                    None => Rstr::na(),
                })
                .collect();
            strs.into_robj()
        })
        .collect();

    let name_strs: Vec<&str> = names.iter().map(|s| s.as_str()).collect();
    match List::from_names_and_values(name_strs, values) {
        Ok(list) => list.into_robj(),
        Err(_) => vec!["Error".to_string(), "Could not build named list".to_string()].into_robj(),
    }
}

fn value_strings(v: Vec<serde_json::Value>) -> Vec<String> {
    v.into_iter().map(|row| row.to_string()).collect()
}

extendr_module! {
    mod EikonDownloader;
    fn rust_get_dg;
    fn rust_get_ts;
}
