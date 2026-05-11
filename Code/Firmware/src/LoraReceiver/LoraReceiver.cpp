#include "LoRaReceiver.h"

static LoRaRelayCallback relayCallback = nullptr;

void LoRa_Receiver_setup()
{


  // Setup LoRa module
  LoRa.setPins(SS, RST, DIO0);

  // Replace the frequency with your regional frequency (e.g., 915E6 for US, 868E6 for EU)
  if (!LoRa.begin(433E6))
  {
    while (1)
      ;
  }

  // Use the same spreading factor as the sender
  LoRa.setSpreadingFactor(12);

  LoRa.receive();
}

void LoRa_Receiver_setRelayCallback(LoRaRelayCallback callback)
{
  relayCallback = callback;
}

void LoRa_Receiver()
{
  // Try to parse packet
  int packetSize = LoRa.parsePacket();

  if (packetSize)
  {
    String payload = "";
    while (LoRa.available())
    {
      payload += (char)LoRa.read();
    }

    Serial.print("LoRa received: ");
    Serial.println(payload);

    if (relayCallback != nullptr)
    {
      relayCallback(payload);
    }
  }
}
