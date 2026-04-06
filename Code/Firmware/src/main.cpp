#include <Arduino.h>
#include "./IR_Receiver/IR_Receiver.h"
#include "./IR_Sender/IR_Sender.h"
#include "./PH_Sensor/PH_sensor.h"
#include "./SCD40/SCD40.h"
#include "./TDSSensor/TDSSensor.h"
#include "./TSL2561/SparkFunTSL2561Example.h"
#include "./RS485Sensor/RS485Sensor.h"  


void setup() {
  Serial.begin(9600);
  IR_receiver_setup();
}

void loop() {
  IR_receiver_loop();
}