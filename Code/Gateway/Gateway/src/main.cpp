// #include <WiFi.h>
// #include <ThingsBoard.h>
// #include <Arduino_MQTT_Client.h>
// #include <Shared_Attribute_Update.h>
// #include <Server_Side_RPC.h>
// #include <Attribute_Request.h>

// #define THINGSBOARD_SERVER "thingsboard.cloud"
// #define TOKEN "UnZmpfOxDol8TvmVHceR"


// const char* ssid = "IPhone";
// const char* password = "12345678";

// constexpr size_t MAX_ATTRIBUTES = 5U;
// constexpr uint32_t MAX_MESSAGE_SIZE = 1024U;

// constexpr char RL1State[] = "RL1State";
// constexpr char RL2State[] = "RL2State";
// constexpr char RL3State[] = "RL3State";
// constexpr char increaseTemp[] = "increaseTemp";
// constexpr char decreaseTemp[] = "decreaseTemp";

// constexpr std::array<const char *, 5U> SHARED_ATTRIBUTES_LIST = {
//   RL1State,
//   RL2State,
//   RL3State,
//   increaseTemp,
//   decreaseTemp,

// };
// WiFiClient espClient;
// Arduino_MQTT_Client mqttClient(espClient);

// //inital used apis
// Server_Side_RPC<3U, 5U> server_side_rpc;
// Shared_Attribute_Update<3U, MAX_ATTRIBUTES> shared_attribute_update; 
// Attribute_Request<2U, MAX_ATTRIBUTES> attribute_request;

// const std::array<IAPI_Implementation*, 3U> apis = {
//     &server_side_rpc,
//     &attribute_request,
//     &shared_attribute_update
// };
// ThingsBoard tb(mqttClient, MAX_MESSAGE_SIZE, Default_Max_Stack_Size, apis.size());

// volatile bool attributesChanged = false;
// unsigned long lastSendTime = 0;
// volatile double temperature = 0.0;
// volatile double humidity = 0.0; 
// volatile double PH = 0.0;
// volatile double TDS = 0.0;
// volatile double CO2 = 0.0;
// volatile double light = 0.0;
// volatile bool RL1 = false;
// volatile bool RL2 = false;
// volatile bool RL3 = false;

// void connectToWiFi() {
//   Serial.println("Dang ket noi WiFi...");

//   WiFi.begin(ssid, password);

//   // Chờ kết nối
//   while (WiFi.status() != WL_CONNECTED) {
//     delay(500);
//     Serial.print(".");
//   }

//   Serial.println("\nDa ket noi WiFi!");
//   Serial.print("IP ESP32: ");
//   Serial.println(WiFi.localIP());
// }



 

// // void processSharedAttributes(const JsonObjectConst &data) {
// //   for (auto it = data.begin(); it != data.end(); ++it) {
// //     if (strcmp(it->key().c_str(), RL1State) == 0) {
// //         Serial.print("Received RL1State: ");
// //     }
// //     else if (strcmp(it->key().c_str(), RL2State  ) == 0) {
// //         Serial.print("Received RL2State: ");
// //     }
// //     else if (strcmp(it->key().c_str(), RL3State) == 0) {
// //         Serial.print("Received RL3State: ");  
// //     }
// //     else if (strcmp(it->key().c_str(), increaseTemp) == 0) {
// //         Serial.print("Received increaseTemp: ");
// //     }
// //     else if (strcmp(it->key().c_str(), decreaseTemp) == 0) {  
// //     }   Serial.print("Received decreaseTemp: ");
 
// //   }
// // }
// // void requestTimedOut() {
// //   Serial.printf("Attribute request timed out did not receive a response in (%llu) microseconds. Ensure client is connected to the MQTT broker and that the keys actually exist on the target device\n", REQUEST_TIMEOUT_MICROSECONDS);
// // }
// void processRPCData(const JsonVariantConst &data, JsonDocument &response) {
//   Serial.println("Received RPC");

//   int test = data["value"];   

//   Serial.println(test);

//   if(test == 1) {
//     digitalWrite(2, HIGH);
//   } else {
//     digitalWrite(2, LOW);
//   }

//   response["status"] = "ok";  // bắt buộc
// }
// const std::array<RPC_Callback, 1U> callbacks = {
//     RPC_Callback("processRPCData", processRPCData)
// };
// void connectToThingsBoard() {
//   Serial.println("Dang ket noi ThingsBoard...");
//   if (!tb.connect(THINGSBOARD_SERVER, TOKEN)) {
//     Serial.println("Ket noi ThingsBoard that bai. Thu lai sau 5 giay...");
//     return;
//   } 
       
//   if (!server_side_rpc.RPC_Subscribe(callbacks.cbegin(), callbacks.cend())) {
//       Serial.println("Failed to subscribe for RPC");
//       return;
//     }
//     Serial.println("Da ket noi ThingsBoard!");
    
//     delay(5000);
//     return;
//   }
// void sendDataToThingsBoard(double temperature, double humidity, double PH, double TDS, double CO2, double light, bool RL1, bool RL2, bool RL3) {
//   if (!tb.connected()) {
//     connectToThingsBoard();
//   }
//   String jsonData = "{";
//   jsonData += "\"temperature\":" + String(temperature) + ","; 
//   jsonData += "\"humidity\":" + String(humidity) + ",";
//   jsonData += "\"PH\":" + String(PH) + ",";
//   jsonData += "\"TDS\":" + String(TDS) + ",";

//   jsonData += "\"CO2\":" + String(CO2) + ",";
//   jsonData += "\"light\":" + String(light) + ",";
//   jsonData += "\"RL1\":" + String(RL1) + ",";
//   jsonData += "\"RL2\":" + String(RL2) + ",";
//   jsonData += "\"RL3\":" + String(RL3);
//   jsonData += "}";
//   tb.sendTelemetryString(jsonData.c_str());

// }
// // const Shared_Attribute_Callback<MAX_ATTRIBUTES> attributes_callback(&processSharedAttributes, SHARED_ATTRIBUTES_LIST.cbegin(), SHARED_ATTRIBUTES_LIST.cend());
// // const Attribute_Request_Callback<MAX_ATTRIBUTES> attribute_shared_request_callback(&processSharedAttributes, REQUEST_TIMEOUT_MICROSECONDS, &requestTimedOut, SHARED_ATTRIBUTES_LIST);
// // const Attribute_Request_Callback<MAX_ATTRIBUTES> attribute_client_request_callback(&processClientAttributes, REQUEST_TIMEOUT_MICROSECONDS, &requestTimedOut, CLIENT_ATTRIBUTES_LIST);
// void setup() {
//   Serial.begin(9600);
//   delay(1000);
//   pinMode(2, OUTPUT);
//   connectToWiFi();
//   mqttClient.set_buffer_size(MAX_MESSAGE_SIZE, MAX_MESSAGE_SIZE);
//   connectToThingsBoard();
  
// }
// void loop() {
//    tb.loop();

//   // if(millis() - lastSendTime > 5000) {
//   //   // Cập nhật dữ liệu cảm biến (giả lập)
//   //   temperature += 0.1;
//   //   humidity += 0.1;
//   //   PH += 0.1;
//   //   TDS += 0.1;
//   //   CO2 += 0.1;
//   //   light += 0.1;
//   //   RL1 = !RL1;
//   //   RL2 = !RL2;
//   //   RL3 = !RL3;

//   //   sendDataToThingsBoard(temperature, humidity, PH, TDS, CO2, light, RL1, RL2, RL3);
//   //   lastSendTime = millis();
//   // }
// }

#include <WiFi.h>
#include <Arduino_MQTT_Client.h>
#include <ThingsBoard.h>

// #include <ArduinoOTA.h> (Uncomment if you are using PlatformIO)

// Wi-Fi and ThingsBoard configuration
constexpr char WIFI_SSID[] = "IPhone";
constexpr char WIFI_PASSWORD[] = "12345678";
constexpr char TOKEN[] = "UnZmpfOxDol8TvmVHceR";
constexpr char THINGSBOARD_SERVER[] = "thingsboard.cloud";
constexpr uint16_t THINGSBOARD_PORT = 1883U;
constexpr uint32_t MAX_MESSAGE_SIZE = 1024U;
constexpr uint32_t SERIAL_DEBUG_BAUD = 9600U;

// Pin definition for the LED
constexpr uint8_t LED_PIN = 2;

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

// Global variables
bool ledState = false;  // LED state
bool subscribed = false; // Indicates if RPC subscription is done

// Initialize WiFi and MQTT clients
WiFiClient wifiClient;
Arduino_MQTT_Client mqttClient(wifiClient);
ThingsBoard tb(mqttClient, MAX_MESSAGE_SIZE);

// Function declarations
void initWiFi();
bool reconnect();
RPC_Response processSetLedStatus(const RPC_Data &data);
RPC_Response processRelay1(const RPC_Data &data);
RPC_Response processRelay2(const RPC_Data &data); 
RPC_Response processRelay3(const RPC_Data &data);
void processTime(const JsonVariantConst& data);
void sendDataToThingsBoard(double temperature, double humidity, double PH, double TDS, double CO2, double light, bool RL1, bool RL2, bool RL3) ;


// Define the array of RPC callbacks
const std::array<RPC_Callback, 4U> callbacks = {
  RPC_Callback{ "setLedStatus", processSetLedStatus },
  RPC_Callback{ "setRelay1Status", processRelay1 },
  RPC_Callback{ "setRelay2Status", processRelay2 },
  RPC_Callback{ "setRelay3Status", processRelay3 }
};

void setup() {
  // Initialize serial communication
  Serial.begin(SERIAL_DEBUG_BAUD);
  
  // Set the LED pin as output
  pinMode(LED_PIN, OUTPUT);
  
  // Small delay to ensure the serial monitor is ready
  delay(1000);
  
  // Initialize Wi-Fi connection
  initWiFi();
}

void loop() {
  // Small delay to avoid overwhelming the loop
  delay(10);

  // Attempt to reconnect if the Wi-Fi connection is lost
  if (!reconnect()) {
    return;
  }

  // Check if we are connected to ThingsBoard
  if (!tb.connected()) {
    // Attempt to connect to ThingsBoard
    Serial.print("Connecting to: ");
    Serial.print(THINGSBOARD_SERVER);
    Serial.print(" with token ");
    Serial.println(TOKEN);
    if (!tb.connect(THINGSBOARD_SERVER, TOKEN, THINGSBOARD_PORT)) {
      Serial.println("Failed to connect");
      return;
    }

    // Subscribe to RPC callbacks
    Serial.println("Subscribing for RPC...");
    if (!tb.RPC_Subscribe(callbacks.cbegin(), callbacks.cend())) {
      Serial.println("Failed to subscribe for RPC");
      return;
    }
  }

  // Control the LED state
  digitalWrite(LED_PIN, ledState ? HIGH : LOW);

  // Request the current time if not already subscribed
  // if (!subscribed) {
  //   Serial.println("Requesting RPC...");
  //   RPC_Request_Callback timeRequestCallback("getCurrentTime", processTime);
  //   if (!tb.RPC_Request(timeRequestCallback)) {
  //     Serial.println("Failed to request for RPC");
  //     return;
  //   }
  //   Serial.println("Request done");
  //   subscribed = true;
  // }

  // Maintain the connection and process incoming messages

    if(millis() - lastSendTime > 5000) {
    // Cập nhật dữ liệu cảm biến (giả lập)
    temperature += 0.1;
    humidity += 0.11;
    PH += 0.15;
    TDS += 0.17;
    CO2 += 0.19;
    light += 0.2;
    RL1 = !RL1;
    RL2 = !RL2;
    RL3 = !RL3;

    sendDataToThingsBoard(temperature, humidity, PH, TDS, CO2, light, RL1, RL2, RL3);
    lastSendTime = millis();
  }
  tb.loop();
}

void initWiFi() {
  // Start the connection to the Wi-Fi network
  Serial.println("Connecting to AP ...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to AP");
}

bool reconnect() {
  // Check the Wi-Fi connection status and reconnect if necessary
  if (WiFi.status() != WL_CONNECTED) {
    initWiFi();
  }
  return WiFi.status() == WL_CONNECTED;
}

RPC_Response processSetLedStatus(const RPC_Data &data) {
  // Process the RPC request to change the LED state
  int dataInt = data;
  ledState = dataInt == 1;  // Update the LED state based on the received data
  Serial.println(ledState ? "LED ON" : "LED OFF");
  return RPC_Response("newStatus", dataInt);  // Respond with the new status
}
RPC_Response processRelay1(const RPC_Data &data) {
  // Process the RPC request to change the LED state
  int dataInt = data;
  RL1 = dataInt == 1;  // Update the LED state based on the received data
  Serial.println(RL1 ? "RELAY1 ON" : "RELAY1 OFF");
  return RPC_Response("newStatus", dataInt);  // Respond with the new status
}
RPC_Response processRelay2(const RPC_Data &data) {
  // Process the RPC request to change the LED state
  int dataInt = data;
  RL2 = dataInt == 1;  // Update the LED state based on the received data
  Serial.println(RL2   ? "RELAY2 ON" : "RELAY2 OFF");
  return RPC_Response("newStatus", dataInt);  // Respond with the new status
}
RPC_Response processRelay3(const RPC_Data &data) {
  // Process the RPC request to change the LED state
  int dataInt = data;
  RL3 = dataInt == 1;  // Update the LED state based on the received data
  Serial.println(RL3 ? "RELAY3 ON" : "RELAY3 OFF");
  return RPC_Response("newStatus", dataInt);  // Respond with the new status
}
void processTime(const JsonVariantConst& data) {
  // Process the RPC response containing the current time
  Serial.print("Received time from ThingsBoard: ");
  Serial.println(data["time"].as<String>());
}
void sendDataToThingsBoard(double temperature, double humidity, double PH, double TDS, double CO2, double light, bool RL1, bool RL2, bool RL3) {
 
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
  tb.sendTelemetryJson(jsonData.c_str());

}
