#include <SPI.h>
#include <LoRa.h>

// LoRa pins
#define SS 10
#define RST 9
#define DIO0 2

void setup() {
  Serial.begin(9600);
  while (!Serial);

  Serial.println("LoRa Receiver");

  // Setup LoRa module
  LoRa.setPins(SS, RST, DIO0);
  
  // Replace the frequency with your regional frequency (e.g., 915E6 for US, 868E6 for EU)
  if (!LoRa.begin(915E6)) {
    Serial.println("Starting LoRa failed!");
    while (1);
  }
  
  // Use the same spreading factor as the sender
  LoRa.setSpreadingFactor(12);
}

void loop() {
  // Try to parse packet
  int packetSize = LoRa.parsePacket();
  
  if (packetSize) {
    // Received a packet
    Serial.print("Received packet '");

    // Read packet
    while (LoRa.available()) {
      Serial.print((char)LoRa.read());
    }

    // Print RSSI
    Serial.print("' with RSSI ");
    Serial.println(LoRa.packetRssi());
  }
}