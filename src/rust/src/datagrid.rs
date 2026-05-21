use std::collections::HashMap;
use std::cmp::min;
use serde_json::{json, Value};
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
            "aw" | "w" | "cw" => Self::Weekly,
            "am" | "m" | "cm" => Self::Monthly,
            "aq" | "q" | "fq" | "fi" | "cq" | "f" => Self::Quarterly,
            "fs" | "fh" | "cs" | "ch" => Self::SemiAnnual,
            "ay" | "y" | "fy" | "cy" => Self::Annual,
            _ => Self::Daily,
        }
    }
}


pub struct Datagrid {
    connection: Connection,
}

impl Datagrid {
    pub fn new(c: Connection) -> Self {
        Self { connection: c }
    }

    fn assemble_payload(
        &self,
        instruments: Vec<String>,
        fields: &Value,
        param: &Option<HashMap<String, String>>,
    ) -> Value {
        match param {
            None => json!({
                "requests": [{
                    "instruments": instruments,
                    "fields": fields,
                }]
            }),
            Some(p) => json!({
                "requests": [{
                    "instruments": instruments,
                    "fields": fields,
                    "parameters": p
                }]
            }),
        }
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
            Err(e) => return EkResults::Err(e),
        };
        let mut payloads: Vec<Value> = Vec::new();
        for chunk in instruments.chunks(group_size) {
            let inst_chunk = chunk.to_vec();
            payloads.push(self.assemble_payload(inst_chunk, &fields, &parameters));
        }

        let res = match self.connection.send_request_async_handler(payloads, direction) {
            Ok(r) => r,
            Err(e) => return EkResults::Err(e),
        };

        if res.is_empty() {
            return EkResults::Err(EkError::NoData("No data returned from Refinitiv".to_string()));
        }

        if *settings.get("raw").unwrap_or(&false) {
            EkResults::Raw(res)
        } else {
            let field_name = settings.get("field_name").copied().unwrap_or(false);
            match to_columns(res, field_name) {
                Ok((names, columns)) => EkResults::Columns { names, columns },
                Err(e) => EkResults::Err(e),
            }
        }
    }
}

fn groups(parameters: &Option<HashMap<String, String>>) -> Result<usize, EkError> {
    let max_rows: usize = 50000;
    let max_instruments = 7000usize;
    let max_group_size = match parameters {
        Some(param) => match param.get("SDate") {
            None => max_instruments,
            Some(s_date) => {
                let start_date = str_to_date(s_date.as_str())?;
                let end_date = match param.get("EDate") {
                    None => Utc::now().date_naive(),
                    Some(value) => str_to_date(value.as_str())?,
                };
                let dur = end_date.signed_duration_since(start_date);
                let frq = Frequency::new(param.get("Frq").unwrap_or(&String::from("d")).as_str());
                let rows_pr = match frq {
                    Frequency::Daily => dur.num_days() as f32,
                    Frequency::Weekly => (dur.num_days() as f32) / 7f32,
                    Frequency::Monthly => (dur.num_days() as f32) / 30f32,
                    Frequency::Quarterly => (dur.num_days() as f32) / 90f32,
                    Frequency::SemiAnnual => (dur.num_days() as f32) / 180f32,
                    Frequency::Annual => (dur.num_days() as f32) / 365f32,
                };
                min(
                    (max_rows as f32 / rows_pr).floor() as usize,
                    max_instruments,
                )
            }
        },
        None => max_instruments,
    };
    Ok(max_group_size)
}

fn fetch_headers(json_like: &Value, field_name: bool) -> Option<Vec<String>> {
    let headers = json_like["responses"][0]["headers"][0].as_array()?;

    let mut names: Vec<String> = Vec::new();
    for value in headers {
        if field_name {
            let n = match value.get("field") {
                None => clean_string(value["displayName"].to_string()),
                Some(r) => clean_string(r.to_string()),
            };
            names.push(n);
        } else {
            names.push(clean_string(value["displayName"].to_string()));
        }
    }
    Some(names)
}

fn to_columns(
    json_like: Vec<Value>,
    field_name: bool,
) -> Result<(Vec<String>, Vec<Vec<Option<String>>>), EkError> {
    // Extract headers
    let mut headers: Vec<String> = Vec::new();
    for request in &json_like {
        if let Some(r) = fetch_headers(request, field_name) {
            headers = r;
            break;
        }
    }

    if headers.is_empty() {
        return Err(EkError::NoHeaders("Could not build headers".to_string()));
    }

    // Extract data into columns
    let mut columns: Vec<Vec<Option<String>>> = vec![Vec::new(); headers.len()];

    for request in &json_like {
        let rows = match request["responses"][0]["data"].as_array() {
            None => continue,
            Some(r) => r,
        };
        for row in rows {
            for (col_idx, col) in columns.iter_mut().enumerate() {
                let val = &row[col_idx];
                if val.is_null() {
                    col.push(None);
                } else {
                    col.push(Some(clean_string(val.to_string())));
                }
            }
        }
    }

    Ok((headers, columns))
}

fn str_to_date(d: &str) -> Result<NaiveDate, EkError> {
    NaiveDate::parse_from_str(d, "%Y-%m-%d").map_err(|_| {
        EkError::DateError(
            "Could not parse date string, please supply ISO8601 format".to_string(),
        )
    })
}
