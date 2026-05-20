#include "LoRaReceiver.h"

#if defined(ARDUINO_ARCH_AVR)
#include <avr/interrupt.h>
#endif

static const uint8_t LORA_RX_BUFFER_SIZE = 96;
static const unsigned long LORA_RX_RECOVERY_INTERVAL_MS = 5000UL;
static LoRaCommandCallback commandCallback = nullptr;
static volatile bool loraPacketInterruptPending = false;
static unsigned long lastLoRaPacketAt = 0;

#if defined(ARDUINO_ARCH_AVR) && defined(PCINT1_vect)
ISR(PCINT1_vect)
{
  if (digitalRead(DIO0) == HIGH)
  {
    loraPacketInterruptPending = true;
  }
}
#endif

static void setupLoRaPacketInterrupt()
{
  pinMode(DIO0, INPUT);

#if defined(digitalPinToPCICR) && defined(digitalPinToPCICRbit) && defined(digitalPinToPCMSK) && defined(digitalPinToPCMSKbit)
  volatile uint8_t *pcicr = digitalPinToPCICR(DIO0);
  volatile uint8_t *pcmsk = digitalPinToPCMSK(DIO0);

  if (pcicr != nullptr && pcmsk != nullptr)
  {
    *pcicr |= _BV(digitalPinToPCICRbit(DIO0));
    *pcmsk |= _BV(digitalPinToPCMSKbit(DIO0));
  }
#endif
}

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
  lastLoRaPacketAt = millis();
  setupLoRaPacketInterrupt();
}

void LoRa_Receiver_setCommandCallback(LoRaCommandCallback callback)
{
  commandCallback = callback;
}

void LoRa_Receiver()
{
  loraPacketInterruptPending = false;

  // Try to parse packet
  int packetSize = LoRa.parsePacket();

  if (packetSize)
  {
    lastLoRaPacketAt = millis();
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
    lastLoRaPacketAt = millis();
  }
  else if (millis() - lastLoRaPacketAt >= LORA_RX_RECOVERY_INTERVAL_MS)
  {
    LoRa.idle();
    LoRa.receive();
    lastLoRaPacketAt = millis();
  }
}
