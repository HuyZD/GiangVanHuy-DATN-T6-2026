#ifndef RELAY_H
#define RELAY_H
#include<Arduino.h>
#define RELAY1_PIN 9 
#define RELAY2_PIN 6


void relay_setup();
void relay1_on();
void relay1_off();
void relay2_on();
void relay2_off();



#endif // RELAY_H