use serde_json::json;
use reqwest::blocking::Response;

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

    pub fn status(&self, port: &i16) -> reqwest::Result<Response> {
        let address = format!("{}:{}/api/status", self.get_url(), port);
        let client = reqwest::blocking::Client::new();
        client.get(address)
            .header("X-tr-applicationid", self.get_app_key())
            .send()
    }

    pub fn handshake(&self) -> serde_json::Value {
        // http://127.0.0.1:9000/api/handshake
        // http://127.0.0.1:9000/api/handshake
        // headers = {'Content-Type': 'application/json', 'x-tr-applicationid': 'f63dab2c283546a187cd6c59894749a2228ce486'}
        let address = format!("{}/api/handshake", self.get_address());

        let app_key = self.get_app_key();
        println!("{}", address);


        let json_body = json!({
            "AppKey": app_key,
            "AppScope": "trapi",
            "ApiVersion": "1"
        });

        let client = reqwest::blocking::Client::new();
        client.post(address)
            .header("CONTENT-TYPE", "application/json")
            .header("x-tr-applicationid", app_key)
            .body(json_body.to_string())
            .send()
            .expect("Could not handshake")
            .json()
            .expect("Could not parse as JSON")
    }


    pub fn send_request(
        &self,
        payload: serde_json::Value,
        direction: &String,
    ) -> reqwest::Result<serde_json::Value> {
        #[derive(serde::Serialize)]
        struct FullRequest {
            Entity: Entity,
        }

        #[derive(serde::Serialize)]
        struct Entity {
            E: String,
            W: serde_json::Value,
        }

        let json_body = FullRequest {
            Entity: Entity {
                E: direction.to_owned(),
                W: payload,
            }
        };

        let app_key = self.get_app_key();

        let client = reqwest::blocking::Client::new();
        return match client
            .post(format!("{}/api/v1/data", self.get_address()))
            .header("CONTENT_TYPE", "application/json")
            .header("x-tr-applicationid", app_key)
            .json(&json_body)
            .send() {
            Ok(r) => { r.json() }
            Err(e) => { Err(e) }
        };
    }

    pub fn query_port(&self) -> Result<i16, ()> {
        for port in 9000..9010i16 {
            println!("Trying {}", port);

            match self.status(&port) {
                Ok(p) => { return Ok(port); }
                Err(e) => { continue; }
            }
        }
        return Err(());
    }
}

