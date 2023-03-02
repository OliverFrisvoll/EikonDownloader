use std::cmp::{max, min};
use crate::connection::Connection;
use chrono::prelude::*;
use polars::error::PolarsResult;
use polars::frame::DataFrame;
use polars::prelude::*;
use polars::prelude::DataType::{Datetime, Float64, Time, Utf8};
use serde_json::{json, Value};
use polars::series::Series;
use crate::utils::clean_string;

pub enum Frequency {
    //tick
    Minute,
    Hour,
    Daily,
    Weekly,
    Monthly,
    Quarterly,
    Yearly,
}

impl Frequency {
    fn as_str(&self) -> &'static str {
        match self {
            Frequency::Minute => { "minute" }
            Frequency::Hour => { "hour" }
            Frequency::Daily => { "daily" }
            Frequency::Weekly => { "weekly" }
            Frequency::Monthly => { "monthly" }
            Frequency::Quarterly => { "quarterly" }
            Frequency::Yearly => { "yearly" }
        }
    }
    pub fn new(v: &str) -> Frequency {
        match v {
            "minute" => { Frequency::Minute }
            "hour" => { Frequency::Hour }
            "weekly" => { Frequency::Weekly }
            "monthly" => { Frequency::Monthly }
            "quarterly" => { Frequency::Quarterly }
            "yearly" => { Frequency::Yearly }
            _ => { Frequency::Daily }
        }
    }
}


pub struct TimeSeries {
    connection: Connection,
}


impl TimeSeries {
    pub fn new(c: Connection) -> Self {
        Self {
            connection: c
        }
    }
}

impl TimeSeries {
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

    fn groups(
        rics: Vec<String>,
        fields: Vec<String>,
        SDate: NaiveDateTime,
        EDate: NaiveDateTime,
        Frq: Frequency,
    ) -> Vec<Value> {
        let trading_days: usize = 252;
        let max_rows: usize = 3000;
        let max_companies: usize = 300;

        let period = EDate.signed_duration_since(SDate);

        let rows_pr = match Frq {
            Frequency::Minute => { (period.num_minutes() as f32 / 2f32).ceil() as usize }
            Frequency::Hour => { (period.num_hours() as f32 / 2f32).ceil() as usize }
            Frequency::Daily => { ((trading_days as f32 / 365f32) * period.num_days() as f32).ceil() as usize }
            Frequency::Weekly => { (period.num_weeks() as f32).ceil() as usize }
            Frequency::Monthly => { ((period.num_days() as f32 / 365f32) * 12f32).ceil() as usize }
            Frequency::Quarterly => { ((period.num_days() as f32 / 365f32) * 4f32).ceil() as usize }
            Frequency::Yearly => { (period.num_days() as f32 / 365f32).ceil() as usize }
        };

        let ric_group_size = if rics.len() > max_companies { max_companies } else { rics.len() };
        let time_groups = ((rows_pr as f32 * ric_group_size as f32) / max_rows as f32).ceil() as usize;

        println!("Ric group size: {}", ric_group_size);
        println!("Time group: {}", time_groups);

        let time_groups = TimeSeries::create_interval(time_groups, SDate, EDate);
        let mut payloads: Vec<Value> = Vec::new();
        for ric_group in rics.chunks(ric_group_size) {
            for (Sd, Ed) in time_groups.iter() {
                payloads.push(TimeSeries::assemble_payload(
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

    pub fn get_timeseries(
        &self,
        rics: Vec<String>,
        fields: Vec<String>,
        Frq: Frequency,
        SDate: NaiveDateTime,
        EDate: NaiveDateTime,
    ) -> Result<DataFrame, String> {
        let direction = String::from("TimeSeries");

        // Creating the payloads
        let payloads = TimeSeries::groups(rics, fields, SDate, EDate, Frq);

        // Sending payloads
        let mut res = Vec::new();
        for payload in payloads {
            let val = self.connection
                .send_request(payload, &direction)
                .expect("Could not receive request (TimeSeries::get_timeseries)");

            if val["timeseriesData"][0]["statusCode"] == "Normal" {
                res.push(val);
            }
        }

        // Exit if no payload yielded results
        if res.len() == 0 {
            return Err(String::from("Did not receive any results"));
        }

        // Converting from json to a Polars DataFrame
        let mut df = TimeSeries::to_dataframe(&res[0])
            .expect("Could not generate first DataFrame (TimeSeries::get_timeseries)");

        if res.len() > 1 {
            for (i, req) in res.iter().enumerate() {
                if i != 0 {
                    let df_n = TimeSeries::to_dataframe(&req)
                        .expect("Could not convert Value to DataFrame (TimeSeries::get_timeseries)");
                    df = df.vstack(&df_n)
                        .expect("Could not combine DataFrames (TimeSeries::get_timeseries)");
                }
            }
        }
        Ok(df)
    }

    fn fetch_headers(json_like: &Value) -> Result<Vec<String>, String> {
        println!("{}", json_like);
        if json_like["timeseriesData"][0]["statusCode"] == "Normal" {
            let mut field_type: Vec<String> = Vec::new();
            for value in json_like["timeseriesData"][0]["fields"]
                .as_array()
                .expect("Could not iter rows") {
                field_type.push(clean_string(value["name"].to_string()));
            }
            field_type.push(String::from("RIC"));
            Ok(field_type)
        } else {
            Err("Status Code not normal".to_string())
        }
    }

    fn to_dataframe(json_like: &Value) -> PolarsResult<DataFrame> {
        let headers = TimeSeries::fetch_headers(json_like)
            .expect("Could not determine headers of data (TimeSeries::to_dataframe)");
        let mut res: Vec<Series> = Vec::new();

        for i in 0..headers.len() {
            let mut ser: Vec<String> = Vec::new();
            for ric in json_like["timeseriesData"].as_array().unwrap() {
                for row in ric["dataPoints"]
                    .as_array()
                    .expect("Could not convert json_like to Array (TimeSeries::to_dataframe)") {
                    if headers[i] == String::from("RIC") {
                        ser.push(clean_string(ric["ric"].to_string()));
                    } else {
                        ser.push(clean_string(row[i].to_string()));
                    }
                }
            }
            res.push(Series::new(headers[i].as_str(), &ser))
        }
        DataFrame::new(res)
    }
}

