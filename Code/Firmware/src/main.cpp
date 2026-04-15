#include <Arduino.h>
#include "./IR_Receiver/IR_Receiver.h"
#include "./IR_Sender/IR_Sender.h"
#include "./PH_Sensor/PH_sensor.h"
#include "./SCD40/SCD40.h"
#include "./TDSSensor/TDSSensor.h"
#include "./TSL2561/SparkFunTSL2561Example.h"
#include "./RS485Sensor/RS485Sensor.h"
#include "./Relay/Relay.h"
#include "./LoraReceiver/LoraReceiver.h"
#include "./LoraSend/LoraSender.h"

// read IR signal from remote control and print to serial monitor
float temperature, humidity, tdsValue, co2Value, phValue;
double lightValue;
bool relay1State, relay2State, relay3State;
String mod = "auto"; // "auto" or "manual"
void setup()
{
  Serial.begin(9600);
  delay(2000);
  while (!Serial)
    ; // delay for Leonardo
  // read IR signal from remote control and print to serial monitor
  // IR_receiver_setup();

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
  RS485_Sensor_read(temperature, humidity);
  LoRa_Receiver();
  LoRa_Sender(temperature, humidity, tdsValue, lightValue, co2Value, phValue, relay1State, relay2State, relay3State);
}
void auto_control()
{
  // Example auto control logic based on sensor readings
  //Co2 control
  if (co2Value > 1000)
  {
    relay1_on(); // Turn on ventilation
    relay1State = true;
  }
  else
  {
    relay1_off();
    relay1State = false;
  }
// Light control
  if (lightValue < 200)
  {
    relay2_on(); // Turn on grow lights
    relay2State = true;
  }
  else
  {
    relay2_off();
    relay2State = false;
  }
// Humidity control
  if (humidity < 50)
  {
    relay3_on(); // Turn on humidifier
    relay3State = true;
  }
  else
  {
    relay3_off();
    relay3State = false;
  }
// Temperature control using IR sender
  if (temperature > 30)
  {
    IR_sender_down(); // Decrease AC temperature
  }
  else if (temperature < 20)
  {
    IR_sender_up(); // Increase AC temperature
  }
  else
  {
    IR_sender_on(); // Keep AC on
  }

}
void manual_control()
{

}
void loop()
{
  // read IR signal from remote control and print to serial monitor
  // IR_receiver();

  if(mod == "auto"){
    auto_control();
  }
  else{
    manual_control();
  }
  sensor_actuator_send();
}