#include "LoRaSender.h"

int counter = 0;
void LoRa_Sender_setup()
{
  Serial.println("LoRa Sender Setup");
  // Setup LoRa module
  LoRa.setPins(SS, RST, DIO0);

  // Replace the frequency with your regional frequency (e.g., 915E6 for US, 868E6 for EU)
  if (!LoRa.begin(915E6))
  {
    Serial.println("Starting LoRa failed!");
    while (1)
      ;
  }

  // Improve sensitivity at the cost of more current consumption
  LoRa.setSpreadingFactor(12);

  // Specify transmission power (can be 5-23 dBm)
  LoRa.setTxPower(20);
}

void LoRa_Sender(float temperature, float humidity, float tdsValue, double lightValue, float co2Value, float phValue, bool relay1State, bool relay2State, bool relay3State)
{
  Serial.println("LoRa Sender");
  Serial.print("Sending packet: ");
  Serial.println(counter);

  // Begin packet
  LoRa.beginPacket();

  // Add message content
  LoRa.print(counter);
  LoRa.print(":"); // End and send packet
  LoRa.print("temperature - ");
  LoRa.print(temperature);
  LoRa.print("humidity - ");
  LoRa.print(humidity);
  LoRa.print("tdsValue - ");
  LoRa.print(tdsValue);
  LoRa.print("lightValue - ");

  LoRa.print(lightValue);
  LoRa.print("co2Value - ");
  LoRa.print(co2Value);
  LoRa.print("phValue - ");
  LoRa.print(phValue);

  LoRa.print("relay1State - ");
  LoRa.print(relay1State);
  LoRa.print("relay2State - ");
  LoRa.print(relay2State);
  LoRa.print("relay3State - ");

  LoRa.print(relay3State);

  LoRa.endPacket();

  counter++;

  delay(5000); // Wait 5 seconds before sending the next message
}