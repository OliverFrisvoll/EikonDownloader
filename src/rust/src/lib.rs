use crate::connection::Connection;
use crate::datagrid::Datagrid;
use extendr_api::prelude::*;
use std::collections::{HashMap, BTreeMap};
use std::path::Iter;
use extendr_api::wrapper::list::{List, KeyValue};

mod connection;
mod datagrid;


/// Eikon status
/// @export
#[extendr]
fn status(api: String, ip: String, port: i16) -> u16 {
    let ek = Connection::new(api, ip, port);
    ek.status(&port)
}


#[extendr]
fn rust_get_dg(
    instruments: Vec<String>,
    fields: Vec<String>,
    param: List,
    api: String,
    ip: String,
    port: i16,
) -> List {
    let mut con = Connection::new(api, ip, port);
    con.query_port().expect("Can't find Refintiv");

    let ek = Datagrid::new(con);
    let params = list_to_hm(param);

    let df = ek.get_datagrid(
        instruments,
        fields,
        Some(params));

    BTreeMap_to_list(df)
}


fn list_to_hm(l: List) -> HashMap<String, String> {
    let mut params = HashMap::new();
    for (key, value) in List::into_hashmap(l).iter() {
        params.insert(key.to_string(), value.as_str().unwrap().to_string());
    }
    params
}

fn BTreeMap_to_list(df: BTreeMap<String, Vec<String>>) -> List {
    let mut names = Vec::new();
    let mut values = Vec::new();

    for (key, value) in df.iter() {
        names.push(key);
        values.push(r!(value));
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
    fn status;
    fn rust_get_dg;
}
