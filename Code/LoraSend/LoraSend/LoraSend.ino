#include <SPI.h>
#include <LoRa.h>

// LoRa pins
#define SS 10
#define RST 9
#define DIO0 2

int counter = 0;

void setup() {
  Serial.begin(9600);
  while (!Serial);

  Serial.println("LoRa Sender");

  // Setup LoRa module
  LoRa.setPins(SS, RST, DIO0);
  
  // Replace the frequency with your regional frequency (e.g., 915E6 for US, 868E6 for EU)
  if (!LoRa.begin(915E6)) {
    Serial.println("Starting LoRa failed!");
    while (1);
  }
  
  // Improve sensitivity at the cost of more current consumption
  LoRa.setSpreadingFactor(12);
  
  // Specify transmission power (can be 5-23 dBm)
  LoRa.setTxPower(20);
}

void loop() {
  Serial.print("Sending packet: ");
  Serial.println(counter);

  // Begin packet
  LoRa.beginPacket();
  
  // Add message content
  LoRa.print("Hello from Arduino ");
  LoRa.print(counter);
  
  // End and send packet
  LoRa.endPacket();

  counter++;
  
  delay(5000);  // Wait 5 seconds before sending the next message
}