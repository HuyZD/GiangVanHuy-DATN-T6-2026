#ifndef IR_RECEIVER_H
#define IR_RECEIVER_H
#include <IRLibRecvPCI.h>
void IR_receiver_setup();
void IR_receiver_loop();    
#define IR_RECV_PIN 4
#endif	//IR_RECEIVER_H