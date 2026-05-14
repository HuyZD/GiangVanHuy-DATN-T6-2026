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
constexpr size_t LORA_MAX_PAYLOAD_SIZE = 255;
constexpr size_t NODE_CONFIG_MAX_PAYLOAD_SIZE = 240;
constexpr size_t CONFIG_COMMAND_PREFIX_LENGTH = sizeof("config:") - 1;
constexpr uint32_t TELEMETRY_REQUEST_INTERVAL_MS = 20000U;
constexpr uint32_t NODE_RESPONSE_TIMEOUT_MS = 20000U;

constexpr uint8_t LED_PIN = 4;

constexpr char ATTR_AUTO_MODE[] = "autoMode";
constexpr char ATTR_LIGHT_MIN[] = "light_min";
constexpr char ATTR_LIGHT_MAX[] = "light_max";
constexpr char ATTR_CO2_MAX[] = "co2_max";
constexpr char ATTR_CO2_SAFE[] = "co2_safe";
constexpr char ATTR_TEMP_MAX[] = "temp_max";
constexpr char ATTR_TEMP_SAFE[] = "temp_safe";
constexpr char ATTR_HUMIDITY_MAX[] = "humidity_max";
constexpr char ATTR_HUMIDITY_SAFE[] = "humidity_safe";
constexpr char ATTR_TDS_MIN[] = "tds_min";
constexpr char ATTR_TDS_MAX[] = "tds_max";
constexpr char ATTR_PH_MIN[] = "ph_min";
constexpr char ATTR_PH_MAX[] = "ph_max";
constexpr char ATTR_AIR_CONDITIONER_TEMP[] = "airConditionerTemp";

constexpr std::array<const char *, 14U> SHARED_CONFIG_ATTRIBUTES = {
  ATTR_AUTO_MODE,
  ATTR_LIGHT_MIN,
  ATTR_LIGHT_MAX,
  ATTR_CO2_MAX,
  ATTR_CO2_SAFE,
  ATTR_TEMP_MAX,
  ATTR_TEMP_SAFE,
  ATTR_HUMIDITY_MAX,
  ATTR_HUMIDITY_SAFE,
  ATTR_TDS_MIN,
  ATTR_TDS_MAX,
  ATTR_PH_MIN,
  ATTR_PH_MAX,
  ATTR_AIR_CONDITIONER_TEMP
};

struct AutoConfig {
  bool autoMode = false;
  double lightMin = 1000.0;
  double lightMax = 1500.0;
  double co2Max = 1000.0;
  double co2Safe = 800.0;
  double tempMax = 30.0;
  double tempSafe = 28.0;
  double humidityMax = 75.0;
  double humiditySafe = 70.0;
  double tdsMin = 400.0;
  double tdsMax = 800.0;
  double phMin = 5.8;
  double phMax = 6.5;
  double airConditionerTemp = 26.0;
};

unsigned long lastSendTime = 0;
unsigned long lastTelemetryRequestTime = 0;
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
AutoConfig autoConfig;

// Global variables
bool ledState = false;  // LED state
bool sharedConfigSubscribed = false;
bool sharedConfigRequested = false;
bool telemetryProbeSent = false;

WiFiClient wifiClient;
Arduino_MQTT_Client mqttClient(wifiClient);
ThingsBoardSized<16U> tb(mqttClient, MAX_MESSAGE_SIZE);

void initWiFi();
void initLoRa();
bool reconnect();
RPC_Response processSetLedStatus(const RPC_Data &data);
RPC_Response processRelay1(const RPC_Data &data);
RPC_Response processRelay2(const RPC_Data &data); 
RPC_Response processAirConditionerPower(const RPC_Data &data);
RPC_Response processAirConditionerTempUp(const RPC_Data &data);
RPC_Response processAirConditionerTempDown(const RPC_Data &data);
void processTime(const JsonVariantConst& data);
void processSharedConfigUpdate(const Shared_Attribute_Data &data);
void processSharedConfigRequest(const Shared_Attribute_Data &data);
void requestTelemetryFromNode();
bool sendRelayCommandToNode(uint8_t relayNumber, bool relayState);
bool sendAirConditionerPowerToNode(bool enabled);
bool sendAirConditionerTempChangeToNode(bool increase);
void sendConfigToNode(const String &configPayload);
bool configPayloadFitsLoRa(const String &configPayload);
bool sendConfigChunkToNode(const String &configPayload);
bool sendLoRaMessage(const String &message);
bool sendLoRaMessageAndWaitAck(const String &message, uint32_t timeoutMs);
bool waitForNodePacket(String &packet, int &packetRssi, uint32_t timeoutMs);
bool isAckPacket(const String &packet);
void processPacket(const String &packet, int packetRssi, bool usePacketRssi);
bool readSerialPacket(String &packet);
bool readLoRaPacket(String &packet, int &packetRssi, bool &packetOverflow);
bool parseSensorPacket(const String &packet, int packetRssi, bool usePacketRssi);
bool parseDoubleField(const String &packet, const char *label, double &value);
bool parseIntField(const String &packet, const char *label, int &value);
bool updateAutoConfig(const Shared_Attribute_Data &data, String &changedPayload);
bool updateBoolAttribute(const Shared_Attribute_Data &data, const char *key, bool &value, String &changedPayload);
bool updateDoubleAttribute(const Shared_Attribute_Data &data, const char *key, double &value, String &changedPayload, uint8_t decimals = 2U);
void appendJsonField(String &payload, const char *key, const String &value);
String buildFullConfigPayload();
void sendDataToThingsBoard(double temperature, double humidity, double PH, double TDS, double CO2, double light, int RSSI, bool RL1, bool RL2) ;


const std::array<RPC_Callback, 2U> callbacks = {
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
    sharedConfigSubscribed = false;
    sharedConfigRequested = false;
  }

  if (!sharedConfigSubscribed) {
    Serial.println("Subscribing for shared config attributes...");
    const Shared_Attribute_Callback callback(&processSharedConfigUpdate, SHARED_CONFIG_ATTRIBUTES.cbegin(), SHARED_CONFIG_ATTRIBUTES.cend());
    if (!tb.Shared_Attributes_Subscribe(callback)) {
      Serial.println("Failed to subscribe for shared config attributes");
      return;
    }
    sharedConfigSubscribed = true;
  }

  if (!sharedConfigRequested) {
    Serial.println("Requesting shared config attributes...");
    const Attribute_Request_Callback callback(&processSharedConfigRequest, SHARED_CONFIG_ATTRIBUTES.cbegin(), SHARED_CONFIG_ATTRIBUTES.cend());
    sharedConfigRequested = tb.Shared_Attributes_Request(callback);
    if (!sharedConfigRequested) {
      Serial.println("Failed to request shared config attributes");
      return;
    }
  }

  digitalWrite(LED_PIN, ledState ? HIGH : LOW);

  if (!telemetryProbeSent) {
    requestTelemetryFromNode();
    telemetryProbeSent = true;
  }

  String packet;
  if (millis() - lastTelemetryRequestTime >= TELEMETRY_REQUEST_INTERVAL_MS) {
    requestTelemetryFromNode();
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
  const bool acknowledged = sendRelayCommandToNode(1, RL1);
  return RPC_Response("acknowledged", acknowledged);
}
RPC_Response processRelay2(const RPC_Data &data) {
  int dataInt = data;
  RL2 = dataInt == 1;
  Serial.println(RL2   ? "RELAY2 ON" : "RELAY2 OFF");
  const bool acknowledged = sendRelayCommandToNode(2, RL2);
  return RPC_Response("acknowledged", acknowledged);
}
RPC_Response processAirConditionerPower(const RPC_Data &data) {
  int dataInt = data;
  const bool enabled = dataInt == 1;
  Serial.println(enabled ? "AIR CONDITIONER ON" : "AIR CONDITIONER OFF");
  const bool acknowledged = sendAirConditionerPowerToNode(enabled);
  return RPC_Response("acknowledged", acknowledged);
}
RPC_Response processAirConditionerTempUp(const RPC_Data &data) {
  (void)data;
  Serial.println("AIR CONDITIONER TEMP UP");
  const bool acknowledged = sendAirConditionerTempChangeToNode(true);
  return RPC_Response("acknowledged", acknowledged);
}
RPC_Response processAirConditionerTempDown(const RPC_Data &data) {
  (void)data;
  Serial.println("AIR CONDITIONER TEMP DOWN");
  const bool acknowledged = sendAirConditionerTempChangeToNode(false);
  return RPC_Response("acknowledged", acknowledged);
}
void processTime(const JsonVariantConst& data) {
  Serial.print("Received time from ThingsBoard: ");
  Serial.println(data["time"].as<String>());
}

void processSharedConfigUpdate(const Shared_Attribute_Data &data) {
  Serial.println("Shared config update received");
  String changedPayload;
  if (updateAutoConfig(data, changedPayload)) {
    sendConfigToNode(changedPayload);
  }
}

void processSharedConfigRequest(const Shared_Attribute_Data &data) {
  Serial.println("Shared config request received");
  String changedPayload;
  updateAutoConfig(data, changedPayload);
  sendConfigToNode(buildFullConfigPayload());
}

void requestTelemetryFromNode() {
  lastTelemetryRequestTime = millis();
  Serial.println("Requesting telemetry from node...");

  if (!sendLoRaMessage("sensor:read")) {
    return;
  }

  String packet;
  int packetRssi = 0;
  if (!waitForNodePacket(packet, packetRssi, NODE_RESPONSE_TIMEOUT_MS)) {
    Serial.println("Node telemetry response timeout");
    return;
  }

  processPacket(packet, packetRssi, true);
}

bool sendRelayCommandToNode(uint8_t relayNumber, bool relayState) {
  String command = "relay";
  command += String(relayNumber);
  command += "-";
  command += relayState ? "1" : "0";

  return sendLoRaMessageAndWaitAck(command, NODE_RESPONSE_TIMEOUT_MS);
}

bool sendAirConditionerPowerToNode(bool enabled) {
  String command = "ac-power-";
  command += enabled ? "1" : "0";
  return sendLoRaMessageAndWaitAck(command, NODE_RESPONSE_TIMEOUT_MS);
}

bool sendAirConditionerTempChangeToNode(bool increase) {
  const String command = increase ? "ac-temp-up" : "ac-temp-down";
  return sendLoRaMessageAndWaitAck(command, NODE_RESPONSE_TIMEOUT_MS);
}

void sendConfigToNode(const String &configPayload) {
  if (configPayload.length() == 0) {
    return;
  }

  if (configPayloadFitsLoRa(configPayload)) {
    sendConfigChunkToNode(configPayload);
    return;
  }

  if (configPayload[0] != '{' || configPayload[configPayload.length() - 1] != '}') {
    Serial.println("Invalid config payload, not sent");
    return;
  }

  Serial.print("Config payload too long, splitting: ");
  Serial.println(CONFIG_COMMAND_PREFIX_LENGTH + configPayload.length());

  String chunk = "{";
  int fieldStart = 1;
  const int payloadEnd = configPayload.length() - 1;

  while (fieldStart < payloadEnd) {
    const int commaIndex = configPayload.indexOf(',', fieldStart);
    const int fieldEnd = (commaIndex >= 0 && commaIndex < payloadEnd) ? commaIndex : payloadEnd;
    const String field = configPayload.substring(fieldStart, fieldEnd);

    String candidate = chunk;
    if (candidate.length() > 1) {
      candidate += ",";
    }
    candidate += field;
    candidate += "}";

    if (!configPayloadFitsLoRa(candidate)) {
      if (chunk.length() == 1) {
        Serial.print("Config field too long, not sent: ");
        Serial.println(field);
        return;
      }

      chunk += "}";
      if (!sendConfigChunkToNode(chunk)) {
        return;
      }
      chunk = "{";
      continue;
    }

    if (chunk.length() > 1) {
      chunk += ",";
    }
    chunk += field;
    fieldStart = fieldEnd + 1;
  }

  if (chunk.length() > 1) {
    chunk += "}";
    sendConfigChunkToNode(chunk);
  }
}

bool configPayloadFitsLoRa(const String &configPayload) {
  return CONFIG_COMMAND_PREFIX_LENGTH + configPayload.length() <= NODE_CONFIG_MAX_PAYLOAD_SIZE;
}

bool sendConfigChunkToNode(const String &configPayload) {
  const String command = "config:" + configPayload;
  Serial.print("Sending config chunk length: ");
  Serial.println(command.length());
  return sendLoRaMessageAndWaitAck(command, NODE_RESPONSE_TIMEOUT_MS);
}

bool sendLoRaMessage(const String &message) {
  if (message.length() > LORA_MAX_PAYLOAD_SIZE) {
    Serial.print("LoRa message too long, not sent: ");
    Serial.println(message.length());
    return false;
  }

  LoRa.idle();
  LoRa.beginPacket();
  LoRa.print(message);
  const int result = LoRa.endPacket();
  LoRa.receive();

  Serial.print("LoRa message ");
  Serial.print(result == 1 ? "sent: " : "failed: ");
  Serial.println(message);
  return result == 1;
}

bool sendLoRaMessageAndWaitAck(const String &message, uint32_t timeoutMs) {
  if (!sendLoRaMessage(message)) {
    return false;
  }

  String packet;
  int packetRssi = 0;
  if (!waitForNodePacket(packet, packetRssi, timeoutMs)) {
    Serial.print("Node ACK timeout for: ");
    Serial.println(message);
    return false;
  }

  if (isAckPacket(packet)) {
    Serial.print("Node ACK received: ");
    Serial.println(packet);
    return true;
  }

  Serial.print("Unexpected node response: ");
  Serial.println(packet);
  return false;
}

bool waitForNodePacket(String &packet, int &packetRssi, uint32_t timeoutMs) {
  const unsigned long startedAt = millis();
  bool packetOverflow = false;

  while (millis() - startedAt < timeoutMs) {
    if (readLoRaPacket(packet, packetRssi, packetOverflow)) {
      lastSendTime = millis();
      if (packetOverflow) {
        Serial.println("LoRa response too long");
        return false;
      }
      return true;
    }

    delay(10);
  }

  return false;
}

bool isAckPacket(const String &packet) {
  return packet == "ack" || packet.startsWith("ack:") || packet.startsWith("ACK");
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
  // int rssiValue = 0;

  if (!parseDoubleField(packet, "temperature", temperatureValue)) return false;
  if (!parseDoubleField(packet, "humidity", humidityValue)) return false;
  if (!parseDoubleField(packet, "tdsValue", tdsSensorValue)) return false;
  if (!parseDoubleField(packet, "lightValue", lightSensorValue)) return false;
  if (!parseDoubleField(packet, "co2Value", co2SensorValue)) return false;
  if (!parseDoubleField(packet, "phValue", phSensorValue)) return false;
  if (!parseIntField(packet, "relay1State", relay1State)) return false;
  if (!parseIntField(packet, "relay2State", relay2State)) return false;
  // if (usePacketRssi) {
  //   rssiValue = packetRssi;
  // } else if (!parseIntField(packet, "RSSI", rssiValue)) {
  //   return false;
  // }

  temperature = temperatureValue;
  humidity = humidityValue;
  TDS = tdsSensorValue;
  light = lightSensorValue;
  CO2 = co2SensorValue;
  PH = phSensorValue;
  RL1 = relay1State == 1;
  RL2 = relay2State == 1;
  // RSSI = rssiValue;

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

bool updateAutoConfig(const Shared_Attribute_Data &data, String &changedPayload) {
  changedPayload = "{";
  bool changed = false;
  changed |= updateBoolAttribute(data, ATTR_AUTO_MODE, autoConfig.autoMode, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_LIGHT_MIN, autoConfig.lightMin, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_LIGHT_MAX, autoConfig.lightMax, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_CO2_MAX, autoConfig.co2Max, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_CO2_SAFE, autoConfig.co2Safe, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_TEMP_MAX, autoConfig.tempMax, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_TEMP_SAFE, autoConfig.tempSafe, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_HUMIDITY_MAX, autoConfig.humidityMax, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_HUMIDITY_SAFE, autoConfig.humiditySafe, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_TDS_MIN, autoConfig.tdsMin, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_TDS_MAX, autoConfig.tdsMax, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_PH_MIN, autoConfig.phMin, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_PH_MAX, autoConfig.phMax, changedPayload);
  changed |= updateDoubleAttribute(data, ATTR_AIR_CONDITIONER_TEMP, autoConfig.airConditionerTemp, changedPayload);
  changedPayload += "}";

  if (!changed) {
    changedPayload = "";
  }
  return changed;
}

bool updateBoolAttribute(const Shared_Attribute_Data &data, const char *key, bool &value, String &changedPayload) {
  if (!data.containsKey(key)) {
    return false;
  }

  const bool newValue = data[key].as<bool>();
  if (newValue == value) {
    return false;
  }

  value = newValue;
  Serial.print("Updated ");
  Serial.print(key);
  Serial.print(": ");
  Serial.println(value ? "true" : "false");

  appendJsonField(changedPayload, key, value ? "true" : "false");
  return true;
}

bool updateDoubleAttribute(const Shared_Attribute_Data &data, const char *key, double &value, String &changedPayload, uint8_t decimals) {
  if (!data.containsKey(key)) {
    return false;
  }

  const double newValue = data[key].as<double>();
  if (newValue == value) {
    return false;
  }

  value = newValue;
  Serial.print("Updated ");
  Serial.print(key);
  Serial.print(": ");
  Serial.println(value);

  appendJsonField(changedPayload, key, String(value, static_cast<unsigned int>(decimals)));
  return true;
}

void appendJsonField(String &payload, const char *key, const String &value) {
  if (payload.length() > 1) {
    payload += ",";
  }
  payload += "\"";
  payload += key;
  payload += "\":";
  payload += value;
}

String buildFullConfigPayload() {
  String payload = "{";
  appendJsonField(payload, ATTR_AUTO_MODE, autoConfig.autoMode ? "true" : "false");
  appendJsonField(payload, ATTR_LIGHT_MIN, String(autoConfig.lightMin, 2));
  appendJsonField(payload, ATTR_LIGHT_MAX, String(autoConfig.lightMax, 2));
  appendJsonField(payload, ATTR_CO2_MAX, String(autoConfig.co2Max, 2));
  appendJsonField(payload, ATTR_CO2_SAFE, String(autoConfig.co2Safe, 2));
  appendJsonField(payload, ATTR_TEMP_MAX, String(autoConfig.tempMax, 2));
  appendJsonField(payload, ATTR_TEMP_SAFE, String(autoConfig.tempSafe, 2));
  appendJsonField(payload, ATTR_HUMIDITY_MAX, String(autoConfig.humidityMax, 2));
  appendJsonField(payload, ATTR_HUMIDITY_SAFE, String(autoConfig.humiditySafe, 2));
  appendJsonField(payload, ATTR_TDS_MIN, String(autoConfig.tdsMin, 2));
  appendJsonField(payload, ATTR_TDS_MAX, String(autoConfig.tdsMax, 2));
  appendJsonField(payload, ATTR_PH_MIN, String(autoConfig.phMin, 2));
  appendJsonField(payload, ATTR_PH_MAX, String(autoConfig.phMax, 2));
  appendJsonField(payload, ATTR_AIR_CONDITIONER_TEMP, String(autoConfig.airConditionerTemp, 2));
  payload += "}";
  return payload;
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
