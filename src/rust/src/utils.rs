use std::collections::HashMap;
use std::fmt;
use polars::prelude::*;
use serde_json::{Value, json};

pub fn clean_string(s: String) -> String {
    s.replace("\"", "")
}

pub enum EkResults {
    DF(DataFrame),
    Raw(Vec<Value>),
    Err(EkError),
}

#[derive(Debug)]
pub enum EkError {
    NoData(String),
    NoHeaders(String),
    NoDataFrame(String),
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
            EkError::NoDataFrame(e) => write!(f, "No dataframe returned: {}", e),
            EkError::AuthError(e) => write!(f, "Authentication error: {}", e),
            EkError::ConnectionError(e) => write!(f, "Connection error: {}", e),
            EkError::ThreadError(e) => write!(f, "Thread error: {}", e),
            EkError::DateError(e) => write!(f, "Date error: {}", e),
            EkError::Error(e) => write!(f, "Error: {}", e)
        }
    }
}

pub enum Fields {
    Params(HashMap<String, HashMap<String, String>>),
    NoParams(Vec<String>),
}

pub fn field_builder(fields: Fields) -> Value {
    let res = match fields {
        Fields::NoParams(fields) => {
            let mut res = Vec::with_capacity(fields.len());
            for f in fields.iter() {
                res.push(json!({"name": f}));
            }
            res
        }
        Fields::Params(fields) => {
            let mut res = Vec::with_capacity(fields.len());
            for (k, v) in fields.iter() {
                res.push(json!({"name": k, "parameters": v}));
            }
            res
        }
    };
    json!(res)
}

fn missing_in_vec<'a>(v1: Vec<&'a str>, v2: &Vec<&'a str>) -> Vec<&'a str> {
    let mut missing = Vec::new();
    for i in v1.into_iter() {
        if !v2.contains(&i) {
            missing.push(i);
        }
    }
    missing
}

fn create_series(header: &str, l: usize) -> Series {
    let value: Option<String> = None;
    let series = Series::new(header, vec![value; l]);
    series
}

pub fn vstack_diag(df1: &DataFrame, df2: DataFrame) -> Result<DataFrame, EkError> {
    let mut long = df1;
    let mut short = df2.clone();

    let long_col = long.get_column_names();
    let short_col = short.get_column_names();
    let missing = missing_in_vec(long_col, &short_col)
        .into_iter()
        .map(|x| create_series(x, short.shape().0))
        .collect::<Vec<Series>>();

    for i in missing.into_iter() {
        short = match short.with_column(i) {
            Ok(r) => r,
            Err(e) => return Err(EkError::Error("Could not add column (vstack_diag)".to_string()))
        }.to_owned()
    }

    let long_col = long.get_column_names();
    let short = match short.select(long_col) {
        Ok(r) => r,
        Err(e) => return Err(EkError::Error("Could not Select columns (vstack_diag)".to_string()))
    };
    match long.vstack(&short) {
        Ok(r) => Ok(r),
        Err(e) => Err(EkError::Error(format!("So it seems my little df concat (the vstack_diag function) trick in Rust did not work, please create an issue on the github. The error message is as following: {}", e.to_string())))
    }
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
        let mut field = HashMap::new();
        let mut param = HashMap::new();
        param.insert("Scale".to_string(), "6".to_string());
        param.insert("Curn".to_string(), "EUR".to_string());
        field.insert("TR.GrossProfit".to_string(), param);
        let answer: Value = json!([{"name": "TR.GrossProfit", "parameters": {"Scale": "6", "Curn": "EUR"}}]);
        let res = field_builder(Fields::Params(field));
        assert_eq!(res, answer);

        let mut field = HashMap::new();
        let mut param = HashMap::new();
        param.insert("Scale".to_string(), "6".to_string());
        param.insert("Curn".to_string(), "EUR".to_string());
        field.insert("TR.GrossProfit".to_string(), param);
        let mut param = HashMap::new();
        param.insert("Curn".to_string(), "EUR".to_string());
        field.insert("TR.CLOSE".to_string(), param);
        let answer: Value = json!([{"name": "TR.GrossProfit", "parameters": {"Scale": "6", "Curn": "EUR"}}, {"name": "TR.CLOSE", "parameters": {"Curn": "EUR"}}]);
        let res = field_builder(Fields::Params(field));
        assert_eq!(res, answer);

        let fields = vec!["TR.GrossProfit".to_string(), "TR.CLOSE".to_string()];
        let answer: Value = json!([{"name": "TR.GrossProfit"}, {"name": "TR.CLOSE"}]);
        let res = field_builder(Fields::NoParams(fields));
        assert_eq!(res, answer);
    }

    #[test]
    fn test_vstack_diag() {
        let long_df = df!(
            "one_column" => &["test", "test2"],
            "two_column" => &["test1", "test4"],
            "three_column" => &["test5", "test1"],
            "four_column" => &["test10", "test12"]
        ).unwrap();
        let short_df = df!(
            "three_column" => &["test7"],
            "one_column" => &["test8"]
        ).unwrap();
        let res_df = df!(
            "one_column" => &[Some("test"), Some("test2"), Some("test8")],
            "two_column" => &[Some("test1"), Some("test4"), None],
            "three_column" => & [Some("test5"), Some("test1"), Some("test7")],
            "four_column" => & [Some("test10"), Some("test12"), None]
        ).unwrap();

        let attempt = vstack_diag(&long_df, short_df).unwrap();

        assert_eq!(res_df, attempt)
    }

}

