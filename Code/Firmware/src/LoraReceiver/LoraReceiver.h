#ifndef LORA_RECEIVER_H
#define LORA_RECEIVER_H     
#include <SPI.h>
#include <LoRa.h>
// LoRa pins
#define SS 10
#define RST A1
#define DIO0 A0

typedef void (*LoRaRelayCallback)(String command);

void LoRa_Receiver_setup();
void LoRa_Receiver_setRelayCallback(LoRaRelayCallback callback);
void LoRa_Receiver();
#endif	//LORA_RECEIVER_H
