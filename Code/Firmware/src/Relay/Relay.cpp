#include "Relay.h"
void relay_setup() {
  // Initialize relay pins as output
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(RELAY3_PIN, OUTPUT);
}   
void relay1_on() {

  digitalWrite(RELAY1_PIN, HIGH); // Turn relay on
}
void relay1_off() {
  
  digitalWrite(RELAY1_PIN, LOW); // Ensure relay is off
}
void relay2_on() {
  digitalWrite(RELAY2_PIN, HIGH); // Turn relay on
}
void relay2_off() {
  digitalWrite(RELAY2_PIN, LOW); // Turn relay off
}
void relay3_on() {
  digitalWrite(RELAY3_PIN, HIGH); // Turn relay on
}
void relay3_off() {
  digitalWrite(RELAY3_PIN, LOW); // Turn relay off
}
 