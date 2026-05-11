#include "LoRaSender.h"

int counter = 0;
static const uint8_t LORA_MAX_PAYLOAD_SIZE = 255;

static void printTelemetryPacket(Print &output, float temperature, float humidity, float tdsValue, double lightValue, float co2Value, float phValue, bool relay1State, bool relay2State)
{
  output.print(F("temperature - "));
  output.print(temperature);
  output.print(F(" humidity - "));
  output.print(humidity);
  output.print(F(" tdsValue - "));
  output.print(tdsValue);
  output.print(F(" lightValue - "));
  output.print(lightValue);
  output.print(F(" co2Value - "));
  output.print(co2Value);
  output.print(F(" phValue - "));
  output.print(phValue);
  output.print(F(" relay1State - "));
  output.print(relay1State ? 1 : 0);
  output.print(F(" relay2State - "));
  output.print(relay2State ? 1 : 0);
}

void LoRa_Sender_setup()
{
  // Serial.println("LoRa Sender Setup");
  // Setup LoRa module
  LoRa.setPins(SS, RST, DIO0);

  // Replace the frequency with your regional frequency (e.g., 915E6 for US, 868E6 for EU)
  if (!LoRa.begin(433E6))
  {
    while (1)
      ;
  }

  // Improve sensitivity at the cost of more current consumption
  LoRa.setSpreadingFactor(12);

  // Specify transmission power (can be 5-23 dBm)
  LoRa.setTxPower(20);

  LoRa.receive();
}

bool LoRa_SendMessage(const String &message)
{
  if (message.length() > LORA_MAX_PAYLOAD_SIZE)
  {
    Serial.print(F("LoRa payload too long: "));
    Serial.println(message.length());
    return false;
  }

  LoRa.idle();
  LoRa.beginPacket();
  LoRa.print(message);
  const int result = LoRa.endPacket();
  LoRa.receive();

  Serial.print(F("LoRa sent: "));
  Serial.println(message);
  return result == 1;
}

bool LoRa_SendAck()
{
  LoRa.idle();
  LoRa.beginPacket();
  LoRa.print(F("ack"));
  const int result = LoRa.endPacket();
  LoRa.receive();

  Serial.print(F("LoRa ACK "));
  Serial.println(result == 1 ? F("sent") : F("failed"));
  return result == 1;
}

void LoRa_Sender(float temperature, float humidity, float tdsValue, double lightValue, float co2Value, float phValue, bool relay1State, bool relay2State)
{
  LoRa.idle();
  LoRa.beginPacket();
  printTelemetryPacket(LoRa, temperature, humidity, tdsValue, lightValue, co2Value, phValue, relay1State, relay2State);
  const int result = LoRa.endPacket();
  LoRa.receive();

  Serial.print(F("LoRa telemetry "));
  Serial.print(result == 1 ? F("sent: ") : F("failed: "));
  printTelemetryPacket(Serial, temperature, humidity, tdsValue, lightValue, co2Value, phValue, relay1State, relay2State);
  Serial.println();

  counter++;
}
