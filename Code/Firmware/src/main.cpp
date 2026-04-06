#include <Arduino.h>
#include "./IR_Receiver/IR_Receiver.h"

void setup() {
  IR_receiver_setup();
}

void loop() {
  IR_receiver_loop();
}