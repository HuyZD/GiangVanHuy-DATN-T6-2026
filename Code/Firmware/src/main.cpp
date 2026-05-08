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
  LoRa_Sender_setup();
}
void sensor_actuator_send()
{
  phValue = PH_Sensor_read();
  co2Value = SCD40_read();
  tdsValue = TDS_Sensor_read();
  lightValue = TSL2561_read();
  RS485_Sensor_read(temperature1, humidity);
  LoRa_Receiver();
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

  sensor_actuator_send();
}