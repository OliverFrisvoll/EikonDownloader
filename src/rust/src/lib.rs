use crate::connection::Connection;
use crate::datagrid::Datagrid;
use crate::timeseries::{TimeSeries, Frequency};
use extendr_api::prelude::*;
use std::collections::HashMap;
use extendr_api::wrapper::list::{List};
use polars::prelude::*;
use chrono::prelude::*;

mod connection;
mod datagrid;
mod utils;
mod timeseries;


#[extendr]
fn rust_get_dg(
    instruments: Vec<String>,
    fields: Vec<String>,
    param: List,
    api: String,
) -> List {
    let mut con = Connection::new(api, "127.0.0.1".to_string(), 9000);
    let port = con.query_port().expect("Can't find Refintiv");
    con.set_port(port);

    let dg = Datagrid::new(con);
    let params = list_to_hm(param);

    let df = dg.get_datagrid(
        instruments,
        fields,
        Some(params))
        .expect("Could not build DataFrame");

    polars_to_r(df)
}

#[extendr]
fn rust_get_ts(
    rics: Vec<String>,
    fields: Vec<String>,
    Frq: &str,
    Start_Date: &str,
    End_Date: &str,
    api: String,
) -> List {
    let mut con = Connection::new(api, "127.0.0.1".to_string(), 9000);
    let port = con.query_port().expect("Can't find Refintiv");
    con.set_port(port);

    let ts = TimeSeries::new(con);

    let SDate = NaiveDateTime::parse_from_str(Start_Date, "%FT%T")
        .unwrap();

    let EDate = NaiveDateTime::parse_from_str(End_Date, "%FT%T")
        .unwrap();

    let Frq = match Frq {
        "minute" => Frequency::Minute,
        "hour" => Frequency::Hour,
        "daily" => Frequency::Daily,
        "weekly" => Frequency::Weekly,
        "monthly" => Frequency::Monthly,
        "quarterly" => Frequency::Quarterly,
        "yearly" => Frequency::Yearly,
        _ => Frequency::Daily,
    };

    let df = ts.get_timeseries(
        rics,
        fields,
        Frq,
        SDate,
        EDate,
    ).unwrap();

    polars_to_r(df)
}


fn list_to_hm(l: List) -> HashMap<String, String> {
    let mut params = HashMap::new();
    for (key, value) in List::into_hashmap(l).iter() {
        params.insert(key.to_string(), value.as_str().unwrap().to_string());
    }
    params
}

fn series_to_r(s: &Series) -> PolarsResult<Robj> {
    s.utf8().map(|ca| ca.into_iter().collect_robj())
}

fn polars_to_r(df: DataFrame) -> List {
    let mut names = Vec::new();
    let mut values = Vec::new();

    for ser in df.iter() {
        names.push(ser.name());
        values.push(series_to_r(&ser).unwrap());
    }

    let mut res = List::from_values(values);
    res.as_robj_mut()
        .set_names(names)
        .unwrap()
        .as_list()
        .unwrap()
}

// f63dab2c283546a187cd6c59894749a2228ce486

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod EikonDownloader;
    fn rust_get_dg;
    fn rust_get_ts;
}
