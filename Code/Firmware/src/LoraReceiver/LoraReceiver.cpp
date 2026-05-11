#include "LoRaReceiver.h"

static const uint8_t LORA_RX_BUFFER_SIZE = 240;
static LoRaCommandCallback commandCallback = nullptr;

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

void LoRa_Receiver_setCommandCallback(LoRaCommandCallback callback)
{
  commandCallback = callback;
}

void LoRa_Receiver()
{
  // Try to parse packet
  int packetSize = LoRa.parsePacket();

  if (packetSize)
  {
    static char payload[LORA_RX_BUFFER_SIZE + 1];
    uint8_t payloadLength = 0;
    bool payloadOverflow = false;

    while (LoRa.available())
    {
      const char c = static_cast<char>(LoRa.read());
      if (payloadLength < LORA_RX_BUFFER_SIZE)
      {
        payload[payloadLength++] = c;
      }
      else
      {
        payloadOverflow = true;
      }
    }
    payload[payloadLength] = '\0';

    Serial.print(F("LoRa received: "));
    Serial.println(payload);
    Serial.print(F("LoRa length: "));
    Serial.println(payloadLength);

    if (payloadOverflow)
    {
      Serial.println(F("LoRa command too long, packet ignored"));
      LoRa.receive();
      return;
    }

    if (commandCallback != nullptr)
    {
      commandCallback(payload);
    }

    LoRa.receive();
  }
}
