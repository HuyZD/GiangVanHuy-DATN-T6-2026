#include "LoRaReceiver.h"

void LoRa_Receiver_setup()
{

  Serial.println("LoRa Receiver Setup");

  // Setup LoRa module
  LoRa.setPins(SS, RST, DIO0);

  // Replace the frequency with your regional frequency (e.g., 915E6 for US, 868E6 for EU)
  if (!LoRa.begin(915E6))
  {
    Serial.println("Starting LoRa failed!");
    while (1)
      ;
  }

  // Use the same spreading factor as the sender
  LoRa.setSpreadingFactor(12);
}

void LoRa_Receiver()
{
  // Try to parse packet
  Serial.println("LoRa Receiver");
  int packetSize = LoRa.parsePacket();

  if (packetSize)
  {
    // Received a packet
    Serial.print("Received packet '");

    // Read packet
    while (LoRa.available())
    {
      Serial.print((char)LoRa.read());
    }

    // Print RSSI
    Serial.print("' with RSSI ");
    Serial.println(LoRa.packetRssi());
  }
}