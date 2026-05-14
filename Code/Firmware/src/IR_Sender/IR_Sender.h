#ifndef IR_SENDER_H
#define IR_SENDER_H
#include <Arduino.h>
#include <IRLibSendBase.h>    //We need the base code
#include <IRLib_HashRaw.h>    //Only use raw sender
#define RAW_DATA_LEN 200

void AirConditioner_sendTemperature(float temperature);

#endif	//IR_SENDER_H   
