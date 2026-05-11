#include <Arduino.h>
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
String mod = "auto"; // "auto" or "manual"

void handleLoRaRelayCommand(String command)
{
  command.trim();
  command.toLowerCase();
  Serial.print("Received command: ");
  Serial.println(command);
  int relayIndex = command.indexOf("relay");
  if (relayIndex < 0)
  {
    Serial.println("Invalid relay command");
    return;
  }

  int separatorIndex = command.indexOf('-', relayIndex);
  if (separatorIndex < 0)
  {
    Serial.println("Invalid relay command");
    return;
  }

  int relayNumber = command.substring(relayIndex + 5, separatorIndex).toInt();
  int relayState = command.substring(separatorIndex + 1).toInt();

  if (relayNumber == 1 && relayState == 1)
  {
    relay1State = true;
    relay1_on();
    Serial.println("RELAY1 ON");
  }
  else if (relayNumber == 1 && relayState == 0)
  {
    relay1State = false;
    relay1_off();
    Serial.println("RELAY1 OFF");
  }
  else if (relayNumber == 2 && relayState == 1)
  {
    relay2State = true;
    relay2_on();
    Serial.println("RELAY2 ON");
  }
  else if (relayNumber == 2 && relayState == 0)
  {
    relay2State = false;
    relay2_off();
    Serial.println("RELAY2 OFF");
  }
  else
  {
    Serial.println("Invalid relay command");
  }
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
  LoRa_Receiver_setRelayCallback(handleLoRaRelayCommand);
  LoRa_Sender_setup();
}
void sensor_actuator_send()
{
  phValue = PH_Sensor_read();
  co2Value = SCD40_read();
  tdsValue = TDS_Sensor_read();
  lightValue = TSL2561_read();
  RS485_Sensor_read(temperature1, humidity);
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

  static unsigned long lastSendTime = 0;
  if (millis() - lastSendTime >= 5000)
  {
    lastSendTime = millis();
    sensor_actuator_send();
  }
}
