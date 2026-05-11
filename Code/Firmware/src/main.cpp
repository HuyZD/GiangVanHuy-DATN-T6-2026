#include <Arduino.h>
#include <stdlib.h>
#include <string.h>
// #include "./IR_Receiver/IR_Receiver.h"
// #include "./IR_Sender/IR_Sender.h"
#include "./PH_Sensor/PH_sensor.h"
#include "./SCD40/SCD40.h"
#include "./TDSSensor/TDSSensor.h"
#include "./TSL2561/SparkFunTSL2561Example.h"
#include "./RS485Sensor/RS485Sensor.h"
#include "./Relay/Relay.h"
#include "./LoraReceiver/LoraReceiver.h"
#include "./LoraSend/LoraSender.h"
#define PowEn3 A3 // 5V
#define PowEn1 A2 // 3.3V
#define PowEn2 7 // 12V

float temperature1, humidity, tdsValue, co2Value, phValue;
double lightValue;
bool relay1State = true, relay2State = true;
char mod[12] = "auto"; // "auto" or "manual"

struct AutoConfig
{
  char mode[12] = "auto";
  float lightMin = 1000.0;
  float lightMax = 1500.0;
  float co2Max = 1000.0;
  float co2Safe = 800.0;
  float tempMax = 30.0;
  float tempSafe = 28.0;
  float humidityMax = 75.0;
  float humiditySafe = 70.0;
  float tdsMin = 400.0;
  float tdsMax = 800.0;
  float phMin = 5.8;
  float phMax = 6.5;
};

AutoConfig autoConfig;

void readSensors();
void sensor_actuator_send();
void handleLoRaCommand(const char *command);
bool commandStartsWith(const char *command, const char *prefix);
bool handleLoRaRelayCommand(const char *command);
bool handleLoRaConfigCommand(const char *command);
bool updateModeConfig(const char *json);
bool updateFloatConfig(const char *json, const char *key, float &value);
const char *findJsonValue(const char *json, const char *key);

void readSensors()
{
  phValue = PH_Sensor_read();
  co2Value = SCD40_read();
  tdsValue = TDS_Sensor_read();
  lightValue = TSL2561_read();
  RS485_Sensor_read(temperature1, humidity);
}

void handleLoRaCommand(const char *rawCommand)
{
  Serial.print(F("Received command: "));
  Serial.println(rawCommand);

  if (commandStartsWith(rawCommand, "sensor"))
  {
    sensor_actuator_send();
    return;
  }

  if (commandStartsWith(rawCommand, "relay"))
  {
    if (handleLoRaRelayCommand(rawCommand))
    {
      LoRa_SendAck();
    }
    return;
  }

  if (commandStartsWith(rawCommand, "config:"))
  {
    if (handleLoRaConfigCommand(rawCommand))
    {
      LoRa_SendAck();
    }
    return;
  }

  if (commandStartsWith(rawCommand, "ac-"))
  {
    Serial.println(F("Air conditioner command received but IR action is not implemented"));
    LoRa_SendAck();
    return;
  }

  Serial.println(F("Unknown LoRa command"));
}

bool commandStartsWith(const char *command, const char *prefix)
{
  while (*prefix != '\0')
  {
    char commandChar = *command++;
    char prefixChar = *prefix++;

    if (commandChar >= 'A' && commandChar <= 'Z')
    {
      commandChar += 'a' - 'A';
    }

    if (prefixChar >= 'A' && prefixChar <= 'Z')
    {
      prefixChar += 'a' - 'A';
    }

    if (commandChar != prefixChar)
    {
      return false;
    }
  }

  return true;
}

bool handleLoRaRelayCommand(const char *command)
{
  if (!commandStartsWith(command, "relay"))
  {
    Serial.println(F("Invalid relay command"));
    return false;
  }

  const char relayNumber = command[5];
  if (command[6] != '-')
  {
    Serial.println(F("Invalid relay command"));
    return false;
  }

  const char relayState = command[7];
  if (command[8] != '\0' || (relayNumber != '1' && relayNumber != '2') || (relayState != '0' && relayState != '1'))
  {
    Serial.println(F("Invalid relay command"));
    return false;
  }

  if (relayNumber == '1' && relayState == '1')
  {
    relay1State = true;
    relay1_on();
    Serial.println(F("RELAY1 ON"));
    return true;
  }
  else if (relayNumber == '1' && relayState == '0')
  {
    relay1State = false;
    relay1_off();
    Serial.println(F("RELAY1 OFF"));
    return true;
  }
  else if (relayNumber == '2' && relayState == '1')
  {
    relay2State = true;
    relay2_on();
    Serial.println(F("RELAY2 ON"));
    return true;
  }
  else if (relayNumber == '2' && relayState == '0')
  {
    relay2State = false;
    relay2_off();
    Serial.println(F("RELAY2 OFF"));
    return true;
  }

  Serial.println(F("Invalid relay command"));
  return false;
}

bool handleLoRaConfigCommand(const char *command)
{
  const char *json = strchr(command, '{');
  if (json == nullptr)
  {
    Serial.println(F("Invalid config command"));
    return false;
  }

  bool changed = false;
  changed |= updateModeConfig(json);
  changed |= updateFloatConfig(json, "light_min", autoConfig.lightMin);
  changed |= updateFloatConfig(json, "light_max", autoConfig.lightMax);
  changed |= updateFloatConfig(json, "co2_max", autoConfig.co2Max);
  changed |= updateFloatConfig(json, "co2_safe", autoConfig.co2Safe);
  changed |= updateFloatConfig(json, "temp_max", autoConfig.tempMax);
  changed |= updateFloatConfig(json, "temp_safe", autoConfig.tempSafe);
  changed |= updateFloatConfig(json, "humidity_max", autoConfig.humidityMax);
  changed |= updateFloatConfig(json, "humidity_safe", autoConfig.humiditySafe);
  changed |= updateFloatConfig(json, "tds_min", autoConfig.tdsMin);
  changed |= updateFloatConfig(json, "tds_max", autoConfig.tdsMax);
  changed |= updateFloatConfig(json, "ph_min", autoConfig.phMin);
  changed |= updateFloatConfig(json, "ph_max", autoConfig.phMax);
  strncpy(mod, autoConfig.mode, sizeof(mod));
  mod[sizeof(mod) - 1] = '\0';

  Serial.println(changed ? F("Config updated") : F("Config received without changes"));
  return true;
}

bool updateModeConfig(const char *json)
{
  const char *valueStart = findJsonValue(json, "mode");
  if (valueStart == nullptr || *valueStart != '"')
  {
    return false;
  }

  valueStart++;
  const char *valueEnd = strchr(valueStart, '"');
  if (valueEnd == nullptr)
  {
    return false;
  }

  char modeBuffer[12];
  const size_t valueLength = min(static_cast<size_t>(valueEnd - valueStart), sizeof(modeBuffer) - 1);
  memcpy(modeBuffer, valueStart, valueLength);
  modeBuffer[valueLength] = '\0';

  strncpy(autoConfig.mode, modeBuffer, sizeof(autoConfig.mode));
  autoConfig.mode[sizeof(autoConfig.mode) - 1] = '\0';
  Serial.print(F("Updated "));
  Serial.print(F("mode"));
  Serial.print(F(": "));
  Serial.println(autoConfig.mode);
  return true;
}

bool updateFloatConfig(const char *json, const char *key, float &value)
{
  const char *valueStart = findJsonValue(json, key);
  if (valueStart == nullptr)
  {
    return false;
  }

  value = atof(valueStart);
  Serial.print(F("Updated "));
  Serial.print(key);
  Serial.print(F(": "));
  Serial.println(value);
  return true;
}

const char *findJsonValue(const char *json, const char *key)
{
  char pattern[24];
  size_t patternIndex = 0;
  pattern[patternIndex++] = '"';

  while (*key != '\0' && patternIndex < sizeof(pattern) - 3)
  {
    pattern[patternIndex++] = *key++;
  }

  pattern[patternIndex++] = '"';
  pattern[patternIndex++] = ':';
  pattern[patternIndex] = '\0';

  const char *valueStart = strstr(json, pattern);
  if (valueStart == nullptr)
  {
    return nullptr;
  }

  valueStart += patternIndex;
  while (*valueStart == ' ')
  {
    valueStart++;
  }
  return valueStart;
}

void setup()
{
  Serial.begin(9600);
  delay(2000);
  while (!Serial);

  // IR_receiver_setup();
  pinMode(PowEn1, OUTPUT);
  pinMode(PowEn2, OUTPUT);
  pinMode(PowEn3, OUTPUT);
  digitalWrite(PowEn1, HIGH); // Bật nguồn 3.3V
  digitalWrite(PowEn2, HIGH); // Bật nguồn 12V

  digitalWrite(PowEn3, LOW); // Bật nguồn 5V
  PH_Sensor_setup();
  SCD40_setup();
  TDS_Sensor_setup();
  TSL2561_setup();
  RS485_Sensor_setup();
  relay_setup();
  LoRa_Receiver_setup();
  LoRa_Receiver_setCommandCallback(handleLoRaCommand);
  LoRa_Sender_setup();
}
void sensor_actuator_send()
{
  readSensors();
  LoRa_Sender(temperature1, humidity, tdsValue, lightValue, co2Value, phValue, relay1State, relay2State);
}
void auto_control()
{


}
void manual_control()
{

}
void loop()
{
  // read IR signal from remote control and print to serial monitor
  // IR_receiver();

  LoRa_Receiver();
}
