#include <WiFi.h>
#include <ThingsBoard.h>
#include <Arduino_MQTT_Client.h>
#include <Shared_Attribute_Update.h>
#include <Server_Side_RPC.h>
#include <Attribute_Request.h>

#define THINGSBOARD_SERVER "thingsboard.cloud"
#define TOKEN "UnZmpfOxDol8TvmVHceR"


const char* ssid = "IPhone";
const char* password = "12345678";

constexpr size_t MAX_ATTRIBUTES = 5U;
constexpr uint32_t MAX_MESSAGE_SIZE = 1024U;

constexpr char RL1State[] = "RL1State";
constexpr char RL2State[] = "RL2State";
constexpr char RL3State[] = "RL3State";
constexpr char increaseTemp[] = "increaseTemp";
constexpr char decreaseTemp[] = "decreaseTemp";

constexpr std::array<const char *, 5U> SHARED_ATTRIBUTES_LIST = {
  RL1State,
  RL2State,
  RL3State,
  increaseTemp,
  decreaseTemp,

};
WiFiClient espClient;
Arduino_MQTT_Client mqttClient(espClient);

//inital used apis
Server_Side_RPC<3U, 5U> server_side_rpc;
Shared_Attribute_Update<3U, MAX_ATTRIBUTES> shared_attribute_update; 
Attribute_Request<2U, MAX_ATTRIBUTES> attribute_request;

const std::array<IAPI_Implementation*, 3U> apis = {
    &server_side_rpc,
    &attribute_request,
    &shared_attribute_update
};
ThingsBoard tb(mqttClient, MAX_MESSAGE_SIZE, Default_Max_Stack_Size, apis.size());

volatile bool attributesChanged = false;
unsigned long lastSendTime = 0;
volatile double temperature = 0.0;
volatile double humidity = 0.0; 
volatile double PH = 0.0;
volatile double TDS = 0.0;
volatile double CO2 = 0.0;
volatile double light = 0.0;
volatile bool RL1 = false;
volatile bool RL2 = false;
volatile bool RL3 = false;

void connectToWiFi() {
  Serial.println("Dang ket noi WiFi...");

  WiFi.begin(ssid, password);

  // Chờ kết nối
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nDa ket noi WiFi!");
  Serial.print("IP ESP32: ");
  Serial.println(WiFi.localIP());
}



 

// void processSharedAttributes(const JsonObjectConst &data) {
//   for (auto it = data.begin(); it != data.end(); ++it) {
//     if (strcmp(it->key().c_str(), RL1State) == 0) {
//         Serial.print("Received RL1State: ");
//     }
//     else if (strcmp(it->key().c_str(), RL2State  ) == 0) {
//         Serial.print("Received RL2State: ");
//     }
//     else if (strcmp(it->key().c_str(), RL3State) == 0) {
//         Serial.print("Received RL3State: ");  
//     }
//     else if (strcmp(it->key().c_str(), increaseTemp) == 0) {
//         Serial.print("Received increaseTemp: ");
//     }
//     else if (strcmp(it->key().c_str(), decreaseTemp) == 0) {  
//     }   Serial.print("Received decreaseTemp: ");
 
//   }
// }
// void requestTimedOut() {
//   Serial.printf("Attribute request timed out did not receive a response in (%llu) microseconds. Ensure client is connected to the MQTT broker and that the keys actually exist on the target device\n", REQUEST_TIMEOUT_MICROSECONDS);
// }
void processRPCData(const JsonVariantConst &data, JsonDocument &response) {
  Serial.println("Received RPC request with data:");
  int test = data.as<int>();
  Serial.println(test);
  if(test == 1) {
    digitalWrite(2, HIGH);
  } else {
    digitalWrite(2, LOW);
  }
  
  delay(100);
}
const std::array<RPC_Callback, 1U> callbacks = {
    RPC_Callback("processRPCData", processRPCData)
};
void connectToThingsBoard() {
  Serial.println("Dang ket noi ThingsBoard...");
  if (!tb.connect(THINGSBOARD_SERVER, TOKEN)) {
    Serial.println("Ket noi ThingsBoard that bai. Thu lai sau 5 giay...");
  } 
       
  if (!server_side_rpc.RPC_Subscribe(callbacks.cbegin(), callbacks.cend())) {
      Serial.println("Failed to subscribe for RPC");
      return;
    }
    Serial.println("Da ket noi ThingsBoard!");
    
    delay(5000);
    return;
  }
void sendDataToThingsBoard(double temperature, double humidity, double PH, double TDS, double CO2, double light, bool RL1, bool RL2, bool RL3) {
  if (!tb.connected()) {
    connectToThingsBoard();
  }
  String jsonData = "{";
  jsonData += "\"temperature\":" + String(temperature) + ","; 
  jsonData += "\"humidity\":" + String(humidity) + ",";
  jsonData += "\"PH\":" + String(PH) + ",";
  jsonData += "\"TDS\":" + String(TDS) + ",";

  jsonData += "\"CO2\":" + String(CO2) + ",";
  jsonData += "\"light\":" + String(light) + ",";
  jsonData += "\"RL1\":" + String(RL1) + ",";
  jsonData += "\"RL2\":" + String(RL2) + ",";
  jsonData += "\"RL3\":" + String(RL3);
  jsonData += "}";
  tb.sendTelemetryString(jsonData.c_str());

}
// const Shared_Attribute_Callback<MAX_ATTRIBUTES> attributes_callback(&processSharedAttributes, SHARED_ATTRIBUTES_LIST.cbegin(), SHARED_ATTRIBUTES_LIST.cend());
// const Attribute_Request_Callback<MAX_ATTRIBUTES> attribute_shared_request_callback(&processSharedAttributes, REQUEST_TIMEOUT_MICROSECONDS, &requestTimedOut, SHARED_ATTRIBUTES_LIST);
// const Attribute_Request_Callback<MAX_ATTRIBUTES> attribute_client_request_callback(&processClientAttributes, REQUEST_TIMEOUT_MICROSECONDS, &requestTimedOut, CLIENT_ATTRIBUTES_LIST);
void setup() {
  Serial.begin(9600);
  delay(1000);
  pinMode(2, OUTPUT);
  connectToWiFi();
  mqttClient.set_buffer_size(MAX_MESSAGE_SIZE, MAX_MESSAGE_SIZE);
  connectToThingsBoard();
  
}
void loop() {

  if(millis() - lastSendTime > 5000) {
    // Cập nhật dữ liệu cảm biến (giả lập)
    temperature += 0.1;
    humidity += 0.1;
    PH += 0.1;
    TDS += 0.1;
    CO2 += 0.1;
    light += 0.1;
    RL1 = !RL1;
    RL2 = !RL2;
    RL3 = !RL3;

    sendDataToThingsBoard(temperature, humidity, PH, TDS, CO2, light, RL1, RL2, RL3);
    lastSendTime = millis();
  }
  delay(2000);
  tb.loop();
}