#ifndef IR_SENDER_H
#define IR_SENDER_H
#include <IRLibSendBase.h>    //We need the base code
#include <IRLib_HashRaw.h>    //Only use raw sender
#define RAW_DATA_LEN 200
extern uint16_t rawDataOn[RAW_DATA_LEN];
extern uint16_t rawDataOff[RAW_DATA_LEN];
void IR_sender_setup();
void IR_sender();  
#endif	//IR_SENDER_H   