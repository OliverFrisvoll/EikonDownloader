use std::any::TypeId;
use crate::connection::Connection;
use crate::datagrid::Datagrid;
use crate::timeseries::{TimeSeries, Interval};
use crate::utils::{EkError, EkResults, field_builder, Fields};
use extendr_api::prelude::*;
use std::collections::HashMap;
use extendr_api::wrapper::list::{List};
use polars::prelude::*;
use chrono::prelude::*;
use std::result::Result;
use extendr_api::ToVectorValue;

mod connection;
mod datagrid;
mod utils;
mod timeseries;


#[extendr]
fn rust_get_dg(
    instruments: Vec<String>,
    fields: Vec<String>,
    param: List,
    settings: List,
    api: String,
    port: i16,
) -> List {
    let mut con = Connection::new(api, "127.0.0.1".to_string(), port);
    let dg = Datagrid::new(con);
    let params = list_to_hm_string(param);
    let settings = list_to_hm_bool(settings);
    let fields = field_builder(Fields::NoParams(fields));

    match dg.get_datagrid(
        instruments,
        fields,
        Some(params),
        settings,
    ) {
        EkResults::DF(df) => {
            match polars_to_r(df) {
                Ok(r) => r,
                Err(e) => List::from_values(vec!["Error".to_string(), e.to_string()])
            }
        }
        EkResults::Raw(r) => List::from_values(Value_String(r)),
        EkResults::Err(e) => List::from_values(vec!["Error".to_string(), e.to_string()])
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
    port: i16,
) -> List {
    let mut con = Connection::new(api, "127.0.0.1".to_string(), port);
    let ts = TimeSeries::new(con);

    let SDate = NaiveDateTime::parse_from_str(Start_Date, "%FT%T")
        .unwrap();

    let EDate = NaiveDateTime::parse_from_str(End_Date, "%FT%T")
        .unwrap();

    let Frq = match Frq {
        "minute" => Interval::Minute,
        "hour" => Interval::Hour,
        "daily" => Interval::Daily,
        "weekly" => Interval::Weekly,
        "monthly" => Interval::Monthly,
        "quarterly" => Interval::Quarterly,
        "yearly" => Interval::Yearly,
        _ => Interval::Daily,
    };

    match ts.get_timeseries(
        rics,
        fields,
        Frq,
        SDate,
        EDate,
    ) {
        EkResults::DF(df) => {
            match polars_to_r(df) {
                Ok(r) => r,
                Err(e) => List::from_values(vec!["Error".to_string(), e.to_string()])
            }
        }
        EkResults::Raw(r) => List::from_values(Value_String(r)),
        EkResults::Err(e) => List::from_values(vec!["Error".to_string(), e.to_string()])
    }
}

fn list_to_hm_string(l: List) -> HashMap<String, String> {
    let mut params: HashMap<String, String> = HashMap::new();
    for (key, value) in List::into_hashmap(l).iter() {
        params.insert(key.to_string(), value.as_str().unwrap().to_string());
    }
    params
}

fn list_to_hm_bool(l: List) -> HashMap<String, bool> {
    let mut params: HashMap<String, bool> = HashMap::new();
    for (key, value) in List::into_hashmap(l).iter() {
        params.insert(key.to_string(), value.as_bool().unwrap());
    }
    params
}

fn series_to_r(s: &Series) -> PolarsResult<Robj> {
    match s.dtype() {
        DataType::Float64 => s.f64().map(|ca| ca.into_iter().collect_robj()),
        DataType::Utf8 => s.utf8().map(|ca| ca.into_iter().collect_robj()),
        _ => Err(PolarsError::NoData(polars::error::ErrString::from("Could not convert series to R object")))
    }
}

fn polars_to_r(df: DataFrame) -> Result<List, EkError> {
    let mut names = Vec::new();
    let mut values = Vec::new();

    for ser in df.iter() {
        names.push(ser.name());
        values.push(match series_to_r(&ser) {
            Ok(r) => r,
            Err(e) => return Err(EkError::Error("Could not convert series to R object".to_string()))
        });
    }

    let mut res = List::from_values(values);
    match res.as_robj_mut()
        .set_names(names) {
        Err(e) => Err(EkError::Error("Could not set names of dataframe".to_string())),
        Ok(r) => match r.as_list() {
            None => Err(EkError::Error("Could not set names of dataframe".to_string())),
            Some(r) => Ok(r)
        },
    }
}

fn Value_String(v: Vec<serde_json::Value>) -> Vec<String> {
    let mut res = Vec::with_capacity(v.capacity());
    for row in v {
        res.push(row.to_string())
    }
    res
}


// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod EikonDownloader;
    fn rust_get_dg;
    fn rust_get_ts;
}
