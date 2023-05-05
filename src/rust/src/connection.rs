use serde_json::{json, Value};
use std::{fmt, thread, time};

use tokio::runtime::Runtime;
use tokio::task::{JoinHandle};
use crate::utils::{EkError};
use log::{debug};

#[derive(Copy, Clone)]
pub enum Direction {
    Datagrid,
    TimeSeries,
}

impl fmt::Display for Direction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Direction::Datagrid => write!(f, "DataGrid_StandardAsync"),
            Direction::TimeSeries => write!(f, "TimeSeries")
        }
    }
}

pub struct Connection {
    app_key: String,
    url: String,
    port: i16,
}

impl Connection {
    pub fn new(app_key: String, ip: String, port: i16) -> Self {
        Self {
            app_key: app_key.to_owned(),
            url: ip.to_owned(),
            port,
        }
    }

    fn get_url(&self) -> String {
        format!("http://{}", self.url)
    }

    fn get_address(&self) -> String { format!("http://{}:{}", self.url, self.port) }

    fn get_app_key(&self) -> &String {
        &self.app_key
    }

    pub fn set_port(&mut self, port: i16) { self.port = port }

    pub fn status(&self, port: &i16) -> reqwest::Result<reqwest::blocking::Response> {
        let address = format!("{}:{}/api/status", self.get_url(), port);
        let client = reqwest::blocking::Client::new();
        client.get(address)
            .header("X-tr-applicationid", self.get_app_key())
            .send()
    }

    pub fn handshake(&self) -> Result<Value, EkError> {
        let address = format!("{}/api/handshake", self.get_address());
        let app_key = self.get_app_key();
        let json_body = json!({"AppKey": app_key,"AppScope": "trapi","ApiVersion": "1"});
        let client = reqwest::blocking::Client::new();
        match client.post(address)
            .header("CONTENT-TYPE", "application/json")
            .header("x-tr-applicationid", app_key)
            .body(json_body.to_string())
            .send() {
            Err(e) => Err(EkError::ConnectionError(e.to_string())),
            Ok(r) => {
                match r.json() {
                    Err(e) => Err(EkError::NoData(e.to_string())),
                    Ok(r) => {
                        debug!("Handshake: {:?}", r);
                        Ok(r)
                    }
                }
            }
        }
    }

    pub fn send_request_async_handler(&self, payloads: Vec<Value>, direction: Direction) -> Result<Vec<Value>, EkError> {
        let rt = match tokio::runtime::Builder::new_multi_thread()
            .worker_threads(12)
            .enable_all()
            .build() {
            Ok(r) => r,
            Err(e) => return Err(EkError::ThreadError(e.to_string()))
        };

        let app_key = self.get_app_key();
        let address = self.get_address();
        let handshake = self.handshake()?;
        let access_token = Connection::bearer(handshake)?;

        let delay = time::Duration::from_millis(250);

        let mut handles = Vec::with_capacity(payloads.len());

        for payload in payloads {
            thread::sleep(delay);
            handles.push(rt.spawn(
                Connection::send_request_async(
                    payload,
                    direction.clone(),
                    address.to_owned(),
                    app_key.to_owned(),
                    access_token.to_owned())))
        }

        let res = Connection::join_handles(handles, &rt)?;
        return Ok(res);
    }

    fn join_handles(handles: Vec<JoinHandle<Result<Option<Value>, EkError>>>, rt: &Runtime) -> Result<Vec<Value>, EkError> {
        let mut res = Vec::new();
        for handle in handles {
            match rt.block_on(handle) {
                Ok(r) => {
                    match r {
                        Ok(opt) => {
                            match opt {
                                Some(v) => { res.push(v) }
                                None => {}
                            }
                        }
                        Err(e) => { return Err(e); }
                    }
                }
                Err(e) => { return Err(EkError::ThreadError(e.to_string())); }
            }
        }
        Ok(res)
    }


    fn bearer(hk: Value) -> Result<String, EkError> {
        match hk.get("access_token") {
            None => { Err(EkError::AuthError("Cannot get bearer access token".to_string())) }
            Some(r) => { Ok(format!("Bearer {}", r.to_string())) }
        }
    }


    fn req_client(json_body: &Value, address: &str, app_key: &str, access_token: Option<&str>) -> reqwest::RequestBuilder {
        let client = reqwest::Client::new();
        let build = client.post(format!("{}/api/v1/data", address))
            .header("CONTENT_TYPE", "application/json")
            .header("x-tr-applicationid", app_key)
            .json(json_body);

        match access_token {
            None => build,
            Some(r) => build.header("Authorization", r)
        }
    }

    fn entity_assembler(payload: &Value, direction: &Direction) -> Value {
        let dir = direction.to_string();
        json!({"Entity": {"E": dir,"W": payload}})
    }

    async fn request_executioner(req: reqwest::RequestBuilder) -> Result<Option<Value>, EkError> {
        let req_res = match req.send().await {
            Ok(r) => r,
            // Err(e) => return Err(EkError::ConnectionError(e.to_string()))
            Err(e) => return Ok(None)
        };

        // Catching non 200 status code
        if !req_res.status().is_success() {
            return Ok(None);
        }

        match req_res.json::<Value>().await {
            Ok(r) => Ok(Some(r)),
            Err(e) => Err(EkError::NoData(e.to_string()))
        }
    }

    async fn send_request_async(
        payload: Value,
        direction: Direction,
        address: String,
        app_key: String,
        access_token: String,
    ) -> Result<Option<Value>, EkError> {
        let body = Connection::entity_assembler(&payload, &direction);
        let mut trial = 0;

        loop {
            trial += 1;
            let req: reqwest::RequestBuilder = Connection::req_client(&body, &address, &app_key, Some(&access_token));

            let json_res = match Connection::request_executioner(req).await {
                Ok(r) => r,
                Err(e) => return Err(e)
            };

            let Some(req_res) = json_res else {
                if trial < 5 {
                    continue;
                } else {
                    return Ok(None);
                }
            };

            match direction {
                Direction::Datagrid => {
                    match req_res.get("responses") {
                        Some(r) => {
                            match r[0].get("ticket") {
                                None => return Ok(Some(req_res)),
                                Some(ticket) => { Connection::ticket_req(ticket, &direction, &address, &app_key); }
                            }
                        }
                        None => {
                            match req_res.get("ErrorCode") {
                                None => return Ok(None),
                                Some(ErrorCode) => {
                                    match ErrorCode.as_u64() {
                                        None => return Err(EkError::Error(format!("Could not parse as Error Code as u64, {}: {}", ErrorCode, req_res["ErrorMessage"]))),
                                        Some(e) => match e {
                                            2504u64 | 500u64 | 400u64 => {}
                                            _ => return Err(EkError::Error(format!("{}: {}", ErrorCode, req_res["ErrorMessage"])))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Direction::TimeSeries => return Ok(Some(req_res))
            }
        }
    }

    async fn ticket_req(ticket: &Value, direction: &Direction, address: &str, app_key: &str) -> Result<Value, EkError> {
        loop {
            let payload = json!({"requests" : [{"ticket" : ticket}]});
            let body = Connection::entity_assembler(&payload, &direction);
            let req = Connection::req_client(&body, address, app_key, None);
            let json_res = match Connection::request_executioner(req).await {
                Ok(r) => r,
                Err(e) => return Err(e)
            };
            match json_res {
                None => continue,
                Some(r) => return Ok(r)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
}
