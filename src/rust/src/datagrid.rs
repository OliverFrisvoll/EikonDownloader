use std::collections::HashMap;
use serde_json::json;
use polars::prelude::*;
use chrono::prelude::*;
use crate::connection::Connection;
use crate::utils::clean_string;


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
        fields: &Vec<String>,
        param: &Option<HashMap<String, String>>,
    ) -> serde_json::Value {
        let fields_formatted: Vec<serde_json::Value> = fields
            .iter()
            .map(|x| json!({"name": x}))
            .collect();

        let res = match param {
            None => {
                json!(
                    {
                        "requests": [{
                            "instruments": instruments,
                            "fields": fields_formatted,
                        }]
                    }
                )
            }
            Some(p) => {
                json!(
                    {
                        "requests": [{
                            "instruments": instruments,
                            "fields": fields_formatted,
                            "parameters": p
                        }]
                    }
                )
            }
        };

        return res;
    }

    fn days_between(sdate: &String, edate: &String) -> usize {
        let sdate = NaiveDate::parse_from_str(sdate, "%Y-%m-%d")
            .expect("Could not parse sdate (Datagrid::days_between)");
        let edate = NaiveDate::parse_from_str(edate, "%Y-%m-%d")
            .expect("Could not parse edate (Datagrid::days_between)");
        return edate.signed_duration_since(sdate)
            .num_days() as usize;
    }

    fn group_size(rics: usize, parameters: &Option<HashMap<String, String>>) -> usize {
        let max_rows: usize = 50000;
        let max_ric: usize = 7000;
        let trading_days: usize = 252;
        let mut ric_groups = if rics / max_ric > 1 { rics / max_ric + 1 } else { 1 };

        let mut groups = match &parameters {
            Some(param) => {
                if param.contains_key("EDate") && param.contains_key("SDate") {
                    let EDate = param.get("EDate").unwrap();
                    let SDate = param.get("SDate").unwrap();
                    let days = Datagrid::days_between(SDate, EDate);

                    let row_estimate = match param.get("Frq") {
                        Some(frq) => {
                            match frq as &str {
                                "D" => { days * rics }
                                "M" => { (days / trading_days) * 12 * rics }
                                "Y" => { (days / trading_days) * rics }
                                _ => { panic!("Frq not found!") }
                            }
                        }
                        None => {
                            days * rics
                        }
                    };

                    return std::cmp::max(row_estimate / max_rows + 1, ric_groups);
                } else {
                    return ric_groups;
                }
            }
            None => {
                return ric_groups;
            }
        };
    }

    pub fn get_datagrid(&self, instruments: Vec<String>,
                        fields: Vec<String>,
                        parameters: Option<HashMap<String, String>>) -> PolarsResult<DataFrame> {
        let direction = String::from("DataGrid_StandardAsync");
        let groups = Datagrid::group_size(instruments.len(), &parameters);

        println!("Groups: {}", groups);

        let mut payloads: Vec<serde_json::Value> = Vec::new();
        for chunk in instruments.chunks(groups as usize) {
            let inst_chunk = chunk.to_vec();
            payloads.push(self.assemble_payload(inst_chunk, &fields, &parameters));
        }


        let mut res = Vec::new();
        for payload in payloads {
            res.push(self.connection.send_request(payload, &direction)
                .expect("Payload error (get_datagrid)"))
        }

        self.to_data_frame(res)
    }


    fn fetch_headers(json_like: &serde_json::Value) -> Vec<String> {
        println!("{}", json_like["responses"][0]["headers"]);

        // TODO, headers contains two fields displayName and field, The last one is not available for instrument sadly.
        json_like["responses"][0]["headers"][0]
            .as_array()
            .expect("Could not unwrap headers in json, (fetch_headers)")
            .iter()
            .map(|x| clean_string(x["displayName"].to_string()))
            .collect()
    }


    fn to_data_frame(&self, json_like: Vec<serde_json::Value>) -> PolarsResult<DataFrame> {
        let headers = Datagrid::fetch_headers(&json_like[0]);

        // Extract data, combine with headers to make a dataframe
        let mut df_vec: Vec<Series> = Vec::new();

        for col in 0..headers.len() {
            let mut ser: Vec<String> = Vec::new();
            for request in &json_like {
                for row in request["responses"][0]["data"]
                    .as_array()
                    .unwrap() {
                    ser.push(clean_string(row[col].to_string()));
                }
            }
            df_vec.push(Series::new(headers[col].as_str(), ser));
        }
        DataFrame::new(df_vec)
    }
}
