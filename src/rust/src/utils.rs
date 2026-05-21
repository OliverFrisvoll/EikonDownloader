use std::collections::HashMap;
use std::fmt;
use serde_json::{json, Value};

pub fn clean_string(s: String) -> String {
    s.replace('"', "")
}

pub enum EkResults {
    Columns {
        names: Vec<String>,
        columns: Vec<Vec<Option<String>>>,
    },
    Raw(Vec<Value>),
    Err(EkError),
}

#[derive(Debug)]
pub enum EkError {
    NoData(String),
    NoHeaders(String),
    AuthError(String),
    ConnectionError(String),
    ThreadError(String),
    DateError(String),
    Error(String),
}

impl fmt::Display for EkError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            EkError::NoData(e) => write!(f, "No data returned: {}", e),
            EkError::NoHeaders(e) => write!(f, "No headers returned: {}", e),
            EkError::AuthError(e) => write!(f, "Authentication error: {}", e),
            EkError::ConnectionError(e) => write!(f, "Connection error: {}", e),
            EkError::ThreadError(e) => write!(f, "Thread error: {}", e),
            EkError::DateError(e) => write!(f, "Date error: {}", e),
            EkError::Error(e) => write!(f, "Error: {}", e),
        }
    }
}

pub enum Fields {
    Params(HashMap<String, HashMap<String, String>>),
    NoParams(Vec<String>),
}

pub fn field_builder(fields: Fields) -> Value {
    let res: Vec<Value> = match fields {
        Fields::NoParams(fields) => fields.iter().map(|f| json!({"name": f})).collect(),
        Fields::Params(fields) => fields
            .iter()
            .map(|(k, v)| json!({"name": k, "parameters": v}))
            .collect(),
    };
    json!(res)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_clean_string() {
        let s = String::from("\"hello\"");
        let res = clean_string(s);
        assert_eq!(res, "hello");
    }

    #[test]
    fn test_field_builder() {
        let fields = vec!["TR.GrossProfit".to_string(), "TR.CLOSE".to_string()];
        let answer: Value = json!([{"name": "TR.GrossProfit"}, {"name": "TR.CLOSE"}]);
        let res = field_builder(Fields::NoParams(fields));
        assert_eq!(res, answer);
    }
}
