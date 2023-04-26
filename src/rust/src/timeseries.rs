use crate::connection::{Connection, Direction};
use crate::utils::{clean_string, EkResults, EkError, vstack_diag};
use chrono::prelude::*;
use polars::error::PolarsResult;
use polars::frame::DataFrame;
use polars::prelude::*;
use serde_json::{json, Value};
use polars::series::Series;
use log::{info, error, debug, trace, warn};

pub enum Interval {
    //tick
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
    pub fn new(v: &str) -> Interval {
        match v {
            "minute" => { Interval::Minute }
            "hour" => { Interval::Hour }
            "weekly" => { Interval::Weekly }
            "monthly" => { Interval::Monthly }
            "quarterly" => { Interval::Quarterly }
            "yearly" => { Interval::Yearly }
            _ => { Interval::Daily }
        }
    }
}


pub struct TimeSeries {
    connection: Connection,
}

impl TimeSeries {
    pub fn new(c: Connection) -> Self
    {
        Self {
            connection: c
        }
    }
}

impl TimeSeries {
    pub fn get_timeseries(
        &self,
        rics: Vec<String>,
        fields: Vec<String>,
        Frq: Interval,
        SDate: NaiveDateTime,
        EDate: NaiveDateTime,
    ) -> EkResults {
        let direction = Direction::TimeSeries;
        // Creating the payloads
        let payloads = groups(rics, fields, SDate, EDate, Frq);
        let res = match self.connection.send_request_async_handler(payloads, direction) {
            Ok(r) => r,
            Err(e) => return EkResults::Err(e),
        };
        if res.is_empty() {
            return EkResults::Err(EkError::NoData("No data returned from Refinitiv".to_string()));
        }


        let mut df_vec = Vec::new();

        for response in res {
            match to_dataframe(response) {
                Err(e) => return EkResults::Err(e),
                Ok(r) => {
                    match r {
                        None => {}
                        Some(r) => df_vec.push(r)
                    }
                }
            }
        }

        let mut df = df_vec[0].to_owned();

        for (i, n_df) in df_vec.into_iter().enumerate() {
            if i != 0 {
                if n_df.shape().1 < df.shape().1 {
                    df = match vstack_diag(&df, n_df) {
                        Ok(r) => r,
                        Err(e) => return EkResults::Err(e),
                    };
                } else if n_df.shape().1 > df.shape().1 {
                    df = match vstack_diag(&n_df, df) {
                        Ok(r) => r,
                        Err(e) => return EkResults::Err(e),
                    };
                } else {
                    let n_df_ordered = match n_df.select(df.get_column_names()) {
                        Ok(r) => r,
                        Err(e) => return EkResults::Err(EkError::Error(e.to_string()))
                    };
                    df = match df.vstack(&n_df_ordered) {
                        Ok(r) => r,
                        Err(e) => return EkResults::Err(EkError::Error(e.to_string()))
                    };
                }
            }
        }
        EkResults::DF(df)
    }
}

/// Divides the request into smaller chunks that adhere to the maximum number of rows and companies
/// that can be requested at once.
///
/// # Arguments
///
/// * `rics` - A vector of RICs
/// * `fields` - A vector of fields
/// * `SDate` - Start date
/// * `EDate` - End date
/// * `Frq` - Frequency
///
/// # Returns
///
/// A vector of payloads that can be sent to the Eikon API
fn groups(
    rics: Vec<String>,
    fields: Vec<String>,
    SDate: NaiveDateTime,
    EDate: NaiveDateTime,
    Frq: Interval,
) -> Vec<Value> {
    let trading_days: usize = 252;
    let max_rows: usize = 3000;
    let max_companies: usize = 300;
    let period = EDate.signed_duration_since(SDate);
    let rows_pr = match Frq {
        Interval::Minute => { (period.num_minutes() as f32 / 2f32).ceil() as usize }
        Interval::Hour => { (period.num_hours() as f32 / 2f32).ceil() as usize }
        Interval::Daily => { ((trading_days as f32 / 365f32) * period.num_days() as f32).ceil() as usize }
        Interval::Weekly => { (period.num_weeks() as f32).ceil() as usize }
        Interval::Monthly => { ((period.num_days() as f32 / 365f32) * 12f32).ceil() as usize }
        Interval::Quarterly => { ((period.num_days() as f32 / 365f32) * 4f32).ceil() as usize }
        Interval::Yearly => { (period.num_days() as f32 / 365f32).ceil() as usize }
    };
    debug!("Rows pr: {}", rows_pr);

    let ric_group_size = if rics.len() > max_companies { max_companies } else { rics.len() };
    debug!("Ric group size: {}", ric_group_size);

    let time_groups = ((rows_pr as f32 * ric_group_size as f32) / max_rows as f32).ceil() as usize;
    debug!("Time group: {}", time_groups);

    let time_groups = create_interval(time_groups, SDate, EDate);
    let mut payloads: Vec<Value> = Vec::new();
    for ric_group in rics.chunks(ric_group_size) {
        for (Sd, Ed) in time_groups.iter() {
            payloads.push(assemble_payload(
                ric_group.into_vec(),
                &fields,
                Frq.as_str(),
                Sd,
                Ed,
            ));
        }
    }
    payloads
}

fn assemble_payload(
    rics: Vec<String>,
    fields: &Vec<String>,
    Frq: &str,
    SDate: &NaiveDateTime,
    EDate: &NaiveDateTime,
) -> Value {
    let value = json!(
            {
                "rics": rics,
                "fields": fields,
                "interval": Frq,
                "startdate": SDate,
                "enddate": EDate
            }

        );
    value
}

fn create_interval(
    groups: usize,
    SDate: NaiveDateTime,
    EDate: NaiveDateTime,
) -> Vec<(NaiveDateTime, NaiveDateTime)> {
    let mut intervals: Vec<(NaiveDateTime, NaiveDateTime)> = Vec::with_capacity(groups);
    let dur = EDate.signed_duration_since(SDate) / groups as i32;
    let mut s = SDate;
    for _ in 0..groups {
        if intervals.is_empty() {
            s = SDate;
        } else {
            (_, s) = intervals.last()
                .unwrap()
                .to_owned();
        }
        intervals.push((s, if s + dur > EDate { EDate } else { s + dur }))
    }
    intervals
}

fn fetch_headers(json_like: &Value) -> Option<Vec<String>> {
    // println!("{}", json_like);
    if json_like["statusCode"] == "Normal" {
        let mut field_type: Vec<String> = Vec::new();
        for value in json_like["fields"]
            .as_array()
            .expect("Could not iter rows") {
            field_type.push(clean_string(value["name"].to_string()));
        }
        field_type.push(String::from("RIC"));
        Some(field_type)
    } else {
        None
    }
}

fn to_dataframe(json_like: Value) -> Result<Option<DataFrame>, EkError> {
    // TODO: Should implement a way to run it again if it fails.

    let mut found = false;
    let mut headers: Vec<String> = Vec::new();

    for request in match json_like["timeseriesData"].as_array() {
        None => return Err(EkError::Error("Could not turn tsData into array".to_string())),
        Some(r) => r
    } {
        match fetch_headers(request) {
            None => continue,
            Some(r) => {
                headers = r;
                found = true;
                break;
            }
        }
    }

    if !found {
        return Ok(None);
    }

    let mut res: Vec<Series> = Vec::with_capacity(headers.len());
    for i in 0..headers.len() {
        let mut ser_string: Vec<String> = Vec::new();
        // let mut ser_f64: Vec<f64> = Vec::new();
        // let mut numeric: bool = false;
        for ric in json_like["timeseriesData"].as_array().unwrap() {
            if ric["statusCode"] != "Normal" {
                continue;
            }
            for row in ric["dataPoints"]
                .as_array()
                .expect("Could not convert json_like to Array (TimeSeries::to_dataframe)") {
                if headers[i] == String::from("RIC") {
                    ser_string.push(clean_string(ric["ric"].to_string()));
                } else {
                    ser_string.push(clean_string(row[i].to_string()))
                    // numeric = row[i].is_number();
                    // match numeric {
                    //     true => ser_f64.push(match row[i].as_f64() {
                    //         None => return Err(EkError::Error("Could not parse column as f64".to_string())),
                    //         Some(r) => r
                    //     }),
                    //     false => ser_string.push(clean_string(row[i].to_string()))
                    // }
                }
            }
        }
        res.push(Series::new(headers[i].as_str(), ser_string))
        // match numeric {
        //     true => res.push(Series::new(headers[i].as_str(), ser_f64)),
        //     false => res.push(Series::new(headers[i].as_str(), ser_string))
        // }
    }
    match DataFrame::new(res) {
        Ok(r) => { Ok(Some(r)) }
        Err(e) => { Err(EkError::NoDataFrame("Could not parse as Polars df".to_string())) }
    }
}
