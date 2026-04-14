#include <WiFi.h>
#include <ThingsBoard.h>
#include <Arduino_MQTT_Client.h>

#define token  "UnZmpfOxDol8TvmVHceR"
#define tb_server "thingsboard.cloud"
#define ap_wifi "3 chú gián"
#define pass_wifi "duocyeutu"

unsigned long preriousTime;

volatile double temperature = 0;
volatile double humidity = 0;
volatile double CO2 = 0;
volatile double PH  = 0;
volatile double TDS = 0;
volatile double AS = 0;
volatile bool RL1 = false;
volatile bool RL2 = false;
volatile bool RL3 = false;

constexpr uint16_t  MAX_MESS_SIZE = 128U;

WiFiClient espClient;
Arduino_MQTT_Client mqttClient(espClient);
ThingsBoardSized<256> tb(mqttClient, MAX_MESS_SIZE);

void connectToWiFi(){
  Serial.println("Connecting to WiFi");
  int temp =  0;
  while (WiFi.status()!= WL_CONNECTED && temp < 20) {
    WiFi.begin(ap_wifi,pass_wifi,6);
    delay(500);
    Serial.print(".");
    temp++;
  }
    if (WiFi.status() != WL_CONNECTED) {
    Serial.println("\nFailed to connect to WiFi.");
  } else {
    Serial.println("\nConnected to WiFi");
  }
}
void connectToThingsBoard(){
  Serial.println(" Connnecting to ThingsBoard !");
  if(!tb.connect(tb_server, token)){
    Serial.println("Fail connecting to ThingsBoard!");

  }
  else {
    Serial.println("Connected to ThingsBoard !");
  }
}
// void sendDataToThingsBoard(double temperature , double humidity, double CO2, double PH, double TDS, double AS, bool RL1, bool RL2, bool RL3 ){
//   String jsonData = "{\"temperature\":" + String(temperature) + ", \"humidity\":" + String(humidity) 
//   + ", \"CO2\":" + String(CO2) + ", \"PH\":" + String(PH) + ", \"TDS\":" + String(TDS) + ", \"AS\":" 
//   + String(AS) + ", \"RL1\":" + String(RL1) + ", \"RL2\":" + String(RL2)+ ", \"RL3\":" + String(RL3) +"}";
//   tb.sendTelemetryJson(jsonData.c_str());
//   Serial.println("Data sent");

// }

void setup() {
  // put your setup code here, to run once:

}

void loop() {
  // put your main code here, to run repeatedly:
  connectToWiFi();
  if(!tb.connected()) connectToThingsBoard();
  if((millis()-preriousTime) > 1000){
    sendDataToThingsBoard( temperature,  humidity,  CO2,  PH,  TDS,  AS,  RL1,  RL2,  RL3);
  }
  preriousTime = millis();
  tb.loop();
}
