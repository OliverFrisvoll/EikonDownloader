use std::collections::HashMap;
use std::cmp::min;
use serde_json::{json, Value};
use polars::prelude::*;
use chrono::prelude::*;
use crate::connection::{Connection, Direction};
use crate::utils::{clean_string, EkResults, EkError};


enum Frequency {
    Daily,
    Weekly,
    Monthly,
    Quarterly,
    SemiAnnual,
    Annual,
}

impl Frequency {
    fn new(frq: &str) -> Self {
        match frq.to_lowercase().as_str() {
            "aw" | "w" | "cw" => { Self::Weekly }
            "am" | "m" | "cm" => { Self::Monthly }
            "aq" | "q" | "fq" | "fi" | "cq" | "f" => { Self::Quarterly }
            "fs" | "fh" | "cs" | "ch" => { Self::SemiAnnual }
            "ay" | "y" | "fy" | "cy" => { Self::Annual }
            _ => { Self::Daily }
        }
    }
}


pub struct Datagrid {
    connection: Connection,
}

impl Datagrid {
    pub fn new(c: Connection) -> Self {
        Self {
            connection: c
        }
    }

    fn assemble_payload(
        &self,
        instruments: Vec<String>,
        fields: &Value,
        param: &Option<HashMap<String, String>>,
    ) -> Value {
        let res = match param {
            None => {
                json!(
                    {
                        "requests": [{
                            "instruments": instruments,
                            "fields": fields,
                        }]
                    }
                )
            }
            Some(p) => {
                json!(
                    {
                        "requests": [{
                            "instruments": instruments,
                            "fields": fields,
                            "parameters": p
                        }]
                    }
                )
            }
        };
        return res;
    }

    pub fn get_datagrid(
        &self,
        instruments: Vec<String>,
        fields: Value,
        parameters: Option<HashMap<String, String>>,
        settings: HashMap<String, bool>,
    ) -> EkResults {
        let direction = Direction::Datagrid;
        let group_size = match groups(&parameters) {
            Ok(r) => r,
            Err(e) => return EkResults::Err(e)
        };
        let mut payloads: Vec<Value> = Vec::new();
        for chunk in instruments.chunks(group_size).into_iter() {
            let inst_chunk = chunk.to_vec();
            payloads.push(self.assemble_payload(inst_chunk, &fields, &parameters));
        }

        let res = match self.connection.send_request_async_handler(payloads, direction) {
            Ok(r) => r,
            Err(e) => return EkResults::Err(e)
        };

        if res.is_empty() {
            return EkResults::Err(EkError::NoData("No data returned from Refinitiv".to_string()));
        }

        if *settings.get("raw").unwrap_or(&false) {
            EkResults::Raw(res)
        } else {
            let field_name = match settings.get("field_name") {
                None => false,
                Some(r) => r.to_owned()
            };
            match to_dataframe(res, field_name) {
                Ok(r) => { EkResults::DF(r) }
                Err(e) => { EkResults::Err(e) }
            }
        }
    }
}

fn groups(parameters: &Option<HashMap<String, String>>) -> Result<usize, EkError> {
    let max_rows: usize = 50000;
    let max_instruments = 7000usize;
    let max_group_size = match parameters {
        Some(param) => {
            match param.get("SDate") {
                None => { max_instruments }
                Some(SDate) => {
                    let start_date = str_to_date(SDate.as_str())?;
                    let end_date = match param.get("EDate") {
                        None => { Utc::now().date_naive() }
                        Some(value) => {
                            str_to_date(value.as_str())?
                        }
                    };
                    let dur = end_date.signed_duration_since(start_date);
                    let frq = Frequency::new(param.get("Frq").unwrap_or(&String::from("d")).as_str());
                    let rows_pr = match frq {
                        Frequency::Daily => { dur.num_days() as f32 }
                        Frequency::Weekly => { (dur.num_days() as f32) / 7f32 }
                        Frequency::Monthly => { (dur.num_days() as f32) / 30f32 }
                        Frequency::Quarterly => { (dur.num_days() as f32) / 90f32 }
                        Frequency::SemiAnnual => { (dur.num_days() as f32) / 180f32 }
                        Frequency::Annual => { (dur.num_days() as f32) / 365f32 }
                    };
                    min((max_rows as f32 / rows_pr as f32).floor() as usize, max_instruments)
                }
            }
        }
        None => { max_instruments }
    };
    Ok(max_group_size)
}

fn fetch_headers(json_like: &Value, field_name: bool) -> Option<Vec<String>> {
    let headers = match json_like["responses"][0]["headers"][0]
        .as_array() {
        None => { return None; }
        Some(r) => { r }
    };

    let mut names: Vec<String> = Vec::new();
    // TODO, headers contains two fields displayName and field, The last one is not available for instrument
    for value in headers {
        if field_name {
            let n = match value.get("field") {
                None => value["displayName"].to_string(),
                Some(r) => r.to_string()
            };
            names.push(n);
        } else {
            names.push(clean_string(value["displayName"].to_string()))
        }
    }
    Some(names)
}

fn to_dataframe(json_like: Vec<Value>, field_name: bool) -> Result<DataFrame, EkError> {

    // Extract headers
    let mut found = false;
    let mut headers: Vec<String> = Vec::new();
    for request in &json_like {
        match fetch_headers(request, field_name) {
            None => { continue; }
            Some(r) => {
                headers = r;
                found = true;
                break;
            }
        }
    }

    if !found {
        return Err(EkError::NoHeaders("Could not build headers".to_string()));
    }
    // Extract data, combine with headers to make a dataframe
    let mut df_vec: Vec<Series> = Vec::with_capacity(headers.len());

    for col in 0..headers.len() {
        let mut ser_string: Vec<Option<String>> = Vec::new(); // Update capacity
        // let mut ser_f64: Vec<Option<f64>> = Vec::new();
        // let mut numeric: bool = false;

        for request in &json_like {
            let rows = match request["responses"][0]["data"]
                .as_array() {
                None => continue,
                Some(r) => r
            };
            for row in rows {
                ser_string.push(Some(clean_string(row[col].to_string())));
                // numeric = row[col].is_number();
                // match numeric {
                //     true => {
                //         ser_f64.push(row[col].as_f64())
                //     }
                //     false => {
                //         ser_string.push(Some(clean_string(row[col].to_string())));
                //     }
                // }
            }
        }
        df_vec.push(Series::new(headers[col].as_str(), ser_string))
        // match numeric {
        //     true => df_vec.push(Series::new(headers[col].as_str(), ser_f64)),
        //     false => df_vec.push(Series::new(headers[col].as_str(), ser_string))
        // }
    }
    match DataFrame::new(df_vec) {
        Ok(r) => Ok(r),
        Err(e) => Err(EkError::NoDataFrame(e.to_string()))
    }
}

fn str_to_date(d: &str) -> Result<NaiveDate, EkError> {
    match NaiveDate::parse_from_str(d, "%Y-%m-%d") {
        Ok(r) => { Ok(r) }
        Err(e) => {
            Err(EkError::DateError("Could not parse SDate string as Date, please supply a ISO8601 compliant Date format".to_string()))
        }
    }
}
