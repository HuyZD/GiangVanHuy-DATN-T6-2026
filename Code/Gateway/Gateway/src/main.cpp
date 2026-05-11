#include <WiFi.h>
#include <Arduino_MQTT_Client.h>
#include <ThingsBoard.h>
#include <SPI.h>
#include <LoRa.h>
#include <array>


constexpr char WIFI_SSID[] = "IPhone";
constexpr char WIFI_PASSWORD[] = "12345678";
constexpr char TOKEN[] = "UnZmpfOxDol8TvmVHceR";
constexpr char THINGSBOARD_SERVER[] = "thingsboard.cloud";
constexpr uint16_t THINGSBOARD_PORT = 1883U;
constexpr uint32_t MAX_MESSAGE_SIZE = 1024U;
constexpr uint32_t SERIAL_DEBUG_BAUD = 9600U;

constexpr uint8_t LORA_SS_PIN = 5;
constexpr uint8_t LORA_RST_PIN = 21;
constexpr uint8_t LORA_DIO0_PIN = 26;
constexpr long LORA_FREQUENCY = 433000000L;
constexpr uint8_t LORA_SPREADING_FACTOR = 12;
constexpr size_t LORA_PACKET_BUFFER_SIZE = 256;

constexpr uint8_t LED_PIN = 4;

unsigned long lastSendTime = 0;
volatile double temperature = 0.0;
volatile double humidity = 0.0; 
volatile double PH = 0.0;
volatile double TDS = 0.0;
volatile double CO2 = 0.0;
volatile double light = 0.0;
volatile int RSSI = 0;
volatile bool RL1 = false;
volatile bool RL2 = false;
String serialPacket = "";

// Global variables
bool ledState = false;  // LED state
bool subscribed = false; // Indicates if RPC subscription is done
bool telemetryProbeSent = false;

WiFiClient wifiClient;
Arduino_MQTT_Client mqttClient(wifiClient);
ThingsBoard tb(mqttClient, MAX_MESSAGE_SIZE);

void initWiFi();
void initLoRa();
bool reconnect();
RPC_Response processSetLedStatus(const RPC_Data &data);
RPC_Response processRelay1(const RPC_Data &data);
RPC_Response processRelay2(const RPC_Data &data); 
void processTime(const JsonVariantConst& data);
void sendRelayCommandToNode(uint8_t relayNumber, bool relayState);
void processPacket(const String &packet, int packetRssi, bool usePacketRssi);
bool readSerialPacket(String &packet);
bool readLoRaPacket(String &packet, int &packetRssi, bool &packetOverflow);
bool parseSensorPacket(const String &packet, int packetRssi, bool usePacketRssi);
bool parseDoubleField(const String &packet, const char *label, double &value);
bool parseIntField(const String &packet, const char *label, int &value);
void sendDataToThingsBoard(double temperature, double humidity, double PH, double TDS, double CO2, double light, int RSSI, bool RL1, bool RL2) ;


const std::array<RPC_Callback, 3U> callbacks = {
  RPC_Callback{ "setLedStatus", processSetLedStatus },
  RPC_Callback{ "setRelay1Status", processRelay1 },
  RPC_Callback{ "setRelay2Status", processRelay2 }
};

void setup() {
  Serial.begin(SERIAL_DEBUG_BAUD);
  
  // Set the LED pin as output
  pinMode(LED_PIN, OUTPUT);
  
  // Small delay to ensure the serial monitor is ready
  delay(1000);
  
  initWiFi();
  initLoRa();
}

void loop() {
  // Small delay to avoid overwhelming the loop
  delay(10);

  if (!reconnect()) {
    return;
  }

  if (!tb.connected()) {
    Serial.print("Connecting to: ");
    Serial.print(THINGSBOARD_SERVER);
    Serial.print(" with token ");
    Serial.println(TOKEN);
    if (!tb.connect(THINGSBOARD_SERVER, TOKEN, THINGSBOARD_PORT)) {
      Serial.println("Failed to connect");
      return;
    }

    Serial.println("Subscribing for RPC...");
    if (!tb.RPC_Subscribe(callbacks.cbegin(), callbacks.cend())) {
      Serial.println("Failed to subscribe for RPC");
      return;
    }

    telemetryProbeSent = false;
  }

  digitalWrite(LED_PIN, ledState ? HIGH : LOW);

  if (!telemetryProbeSent) {
    sendDataToThingsBoard(1, 1, 1, 1, 1, 1, 1, true, true);
    telemetryProbeSent = true;
  }

  int packetRssi = 0;
  bool packetOverflow = false;
  String packet;
  if (readLoRaPacket(packet, packetRssi, packetOverflow)) {
    if (packetOverflow) {
      Serial.println("LoRa packet too long, telemetry was not sent");
    } else {
      processPacket(packet, packetRssi, true);
    }
    lastSendTime = millis();
  }

  if (readSerialPacket(packet)) {
    processPacket(packet, RSSI, false);
    lastSendTime = millis();
  }
  tb.loop();
}

void initWiFi() {
  Serial.println("Connecting to AP ...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to AP");
}

void initLoRa() {
  Serial.println("LoRa Receiver");
  LoRa.setPins(LORA_SS_PIN, LORA_RST_PIN, LORA_DIO0_PIN);

  if (!LoRa.begin(LORA_FREQUENCY)) {
    Serial.println("Starting LoRa failed!");
    while (1) {
      delay(1000);
    }
  }

  LoRa.setSpreadingFactor(LORA_SPREADING_FACTOR);
  LoRa.receive();
  Serial.println("LoRa started");
}

bool reconnect() {
  if (WiFi.status() != WL_CONNECTED) {
    initWiFi();
  }
  return WiFi.status() == WL_CONNECTED;
}

RPC_Response processSetLedStatus(const RPC_Data &data) {
  int dataInt = data;
  ledState = dataInt == 1;  // Update the LED state based on the received data
  Serial.println(ledState ? "LED ON" : "LED OFF");
  return RPC_Response("newStatus", dataInt);  // Respond with the new status
}
RPC_Response processRelay1(const RPC_Data &data) {
  int dataInt = data;
  RL1 = dataInt == 1;
  Serial.println(RL1 ? "RELAY1 ON" : "RELAY1 OFF");
  sendRelayCommandToNode(1, RL1);
  return RPC_Response("newStatus", dataInt);
}
RPC_Response processRelay2(const RPC_Data &data) {
  int dataInt = data;
  RL2 = dataInt == 1;
  Serial.println(RL2   ? "RELAY2 ON" : "RELAY2 OFF");
  sendRelayCommandToNode(2, RL2);
  return RPC_Response("newStatus", dataInt);
}
void processTime(const JsonVariantConst& data) {
  Serial.print("Received time from ThingsBoard: ");
  Serial.println(data["time"].as<String>());
}

void sendRelayCommandToNode(uint8_t relayNumber, bool relayState) {
  String command = "relay";
  command += String(relayNumber);
  command += "-";
  command += relayState ? "1" : "0";

  LoRa.idle();
  LoRa.beginPacket();
  LoRa.print(command);
  const int result = LoRa.endPacket();
  LoRa.receive();

  Serial.print("LoRa command ");
  Serial.print(result == 1 ? "sent: " : "failed: ");
  Serial.println(command);
}

void processPacket(const String &packet, int packetRssi, bool usePacketRssi) {
  Serial.print("Packet received: ");
  Serial.println(packet);

  if (parseSensorPacket(packet, packetRssi, usePacketRssi)) {
    sendDataToThingsBoard(temperature, humidity, PH, TDS, CO2, light, RSSI, RL1, RL2);
  } else {
    Serial.println("Invalid packet format, telemetry was not sent");
  }
}

bool readSerialPacket(String &packet) {
  while (Serial.available() > 0) {
    const char c = static_cast<char>(Serial.read());

    if (c == '\r') {
      continue;
    }

    if (c == '\n') {
      serialPacket.trim();
      if (serialPacket.length() == 0) {
        return false;
      }

      packet = serialPacket;
      serialPacket = "";
      return true;
    }

    serialPacket += c;
    if (serialPacket.length() > 300) {
      serialPacket = "";
      Serial.println("Packet too long, buffer was cleared");
      return false;
    }
  }

  return false;
}

bool readLoRaPacket(String &packet, int &packetRssi, bool &packetOverflow) {
  const int packetSize = LoRa.parsePacket();
  if (packetSize <= 0) {
    return false;
  }

  packet = "";
  packetOverflow = false;
  while (LoRa.available()) {
    const char c = static_cast<char>(LoRa.read());
    if (packet.length() < LORA_PACKET_BUFFER_SIZE - 1) {
      packet += c;
    } else {
      packetOverflow = true;
    }
  }

  packetRssi = LoRa.packetRssi();
  packet.trim();
  LoRa.receive();
  return packet.length() > 0 || packetOverflow;
}

bool parseSensorPacket(const String &packet, int packetRssi, bool usePacketRssi) {
  double temperatureValue = 0.0;
  double humidityValue = 0.0;
  double tdsSensorValue = 0.0;
  double lightSensorValue = 0.0;
  double co2SensorValue = 0.0;
  double phSensorValue = 0.0;
  int relay1State = 0;
  int relay2State = 0;
  int rssiValue = 0;

  if (!parseDoubleField(packet, "temperature", temperatureValue)) return false;
  if (!parseDoubleField(packet, "humidity", humidityValue)) return false;
  if (!parseDoubleField(packet, "tdsValue", tdsSensorValue)) return false;
  if (!parseDoubleField(packet, "lightValue", lightSensorValue)) return false;
  if (!parseDoubleField(packet, "co2Value", co2SensorValue)) return false;
  if (!parseDoubleField(packet, "phValue", phSensorValue)) return false;
  if (!parseIntField(packet, "relay1State", relay1State)) return false;
  if (!parseIntField(packet, "relay2State", relay2State)) return false;
  if (usePacketRssi) {
    rssiValue = packetRssi;
  } else if (!parseIntField(packet, "RSSI", rssiValue)) {
    return false;
  }

  temperature = temperatureValue;
  humidity = humidityValue;
  TDS = tdsSensorValue;
  light = lightSensorValue;
  CO2 = co2SensorValue;
  PH = phSensorValue;
  RL1 = relay1State == 1;
  RL2 = relay2State == 1;
  RSSI = rssiValue;

  return true;
}

bool parseDoubleField(const String &packet, const char *label, double &value) {
  int fieldStart = packet.indexOf(label);
  if (fieldStart < 0) {
    Serial.print("Missing field: ");
    Serial.println(label);
    return false;
  }

  int valueStart = packet.indexOf('-', fieldStart);
  if (valueStart < 0) {
    Serial.print("Missing separator for field: ");
    Serial.println(label);
    return false;
  }

  if (valueStart + 1 < packet.length() && packet[valueStart + 1] == ' ') {
    valueStart++;
  }
  while (valueStart < packet.length() && packet[valueStart] == ' ') {
    valueStart++;
  }

  value = packet.substring(valueStart).toDouble();
  return true;
}

bool parseIntField(const String &packet, const char *label, int &value) {
  int fieldStart = packet.indexOf(label);
  if (fieldStart < 0) {
    Serial.print("Missing field: ");
    Serial.println(label);
    return false;
  }

  int valueStart = packet.indexOf('-', fieldStart);
  if (valueStart < 0) {
    Serial.print("Missing separator for field: ");
    Serial.println(label);
    return false;
  }

  if (valueStart + 1 < packet.length() && packet[valueStart + 1] == ' ') {
    valueStart++;
  }
  while (valueStart < packet.length() && packet[valueStart] == ' ') {
    valueStart++;
  }

  value = packet.substring(valueStart).toInt();
  return true;
}

void sendDataToThingsBoard(double temperature, double humidity, double PH, double TDS, double CO2, double light, int RSSI, bool RL1, bool RL2) {
 
  String jsonData = "{";
  jsonData += "\"TEMPERATURE\":" + String(temperature) + ","; 
  jsonData += "\"HUMIDITY\":" + String(humidity) + ",";
  jsonData += "\"PH\":" + String(PH) + ",";
  jsonData += "\"TDS\":" + String(TDS) + ",";

  jsonData += "\"CO2\":" + String(CO2) + ",";
  jsonData += "\"LIGHT\":" + String(light) + ",";
  jsonData += "\"RSSI\":" + String(RSSI) + ",";
  jsonData += "\"RL1\":" + String(RL1) + ",";
  jsonData += "\"RL2\":" + String(RL2);
  jsonData += "}";
  const bool sent = tb.sendTelemetryJson(jsonData.c_str());
  Serial.print("Telemetry ");
  Serial.print(sent ? "OK: " : "FAILED: ");
  Serial.println(jsonData);

}
