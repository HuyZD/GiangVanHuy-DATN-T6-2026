#ifndef RELAY_H
#define RELAY_H
#include<Arduino.h>
#define RELAY1_PIN 9 
#define RELAY2_PIN A6
#define RELAY3_PIN A7

void relay_setup();
void relay1_on();
void relay1_off();
void relay2_on();
void relay2_off();
void relay3_on();
void relay3_off();


#endif // RELAY_H