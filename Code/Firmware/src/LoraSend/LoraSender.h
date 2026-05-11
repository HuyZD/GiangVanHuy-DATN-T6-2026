#ifndef LORA_SENDER_H
#define LORA_SENDER_H

#include <SPI.h>
#include <LoRa.h>

// LoRa pins
#define SS 10
#define RST A1
#define DIO0 A0
extern int counter;
void LoRa_Sender_setup();
void LoRa_Sender(float temperature, float humidity, float tdsValue, double lightValue, float co2Value, float phValue, bool relay1State, bool relay2State);
bool LoRa_SendMessage(const String &message);
bool LoRa_SendAck();

#endif	//LORA_SENDER_H
