#include <SPI.h>
#include <LoRa.h>
#include <ModbusMaster.h>
#define MAX485_CONTROL 4  
// LoRa pins
#define SS 10
#define RST A1
#define DIO0 A0
#define  PowEn1 A2
#define PowEn3 A3 // 5V
#define PowEn1 A2 // 3.3V
#define PowEn2 7 // 12V
int counter = 0;
ModbusMaster node;
void preTransmission() {
  digitalWrite(MAX485_CONTROL, HIGH);
}

// chuyển sang chế độ nhận
void postTransmission() {
  digitalWrite(MAX485_CONTROL, LOW);
}
void setup() {
  Serial.begin(9600);
  while (!Serial);

  Serial.println("LoRa Sender");
    //  Bật nguồn LoRa
  pinMode(PowEn1, OUTPUT);
  digitalWrite(PowEn1, HIGH);  // HIGH = bật nguồn
  pinMode(PowEn2, OUTPUT);
  digitalWrite(PowEn2, HIGH); 
    pinMode(PowEn3, OUTPUT);
  digitalWrite(PowEn3, LOW); 



  // Setup LoRa module
  LoRa.setPins(SS, RST, DIO0);
  
  // Replace the frequency with your regional frequency (e.g., 915E6 for US, 868E6 for EU)
  if (!LoRa.begin(433E6)) {
   // Serial.println("Starting LoRa failed!");
    while (1);
  }
  
  // Improve sensitivity at the cost of more current consumption
  LoRa.setSpreadingFactor(12);
  
  // Specify transmission power (can be 5-23 dBm)
  LoRa.setTxPower(20);

    pinMode(MAX485_CONTROL, OUTPUT);
  digitalWrite(MAX485_CONTROL, LOW);

  node.begin(1, Serial); // 👈 dùng Serial thay vì rs485

  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);
}

void loop() {
    uint8_t result;

  result = node.readHoldingRegisters(0x0300, 2);

  if (result == node.ku8MBSuccess) {
      Serial.print("Sending packet: ");
  Serial.println(counter);
    uint16_t temp_raw = node.getResponseBuffer(0);
    uint16_t hum_raw  = node.getResponseBuffer(1);

    float temperature = temp_raw / 10.0;
    float humidity    = hum_raw / 10.0;
      // Begin packet
  LoRa.beginPacket();
  
  // Add message content
  LoRa.print("temp:");
  LoRa.println(temperature);
  LoRa.print("hum:");
  LoRa.println(humidity);
 // LoRa.print(counter);
  
  // End and send packet
  LoRa.endPacket(true);

  counter++;
    // ⚠️ KHÔNG in Serial nữa vì đang dùng làm RS485
    // -> nếu in sẽ lỗi dữ liệu
  } else {
    
  }
  // Serial.print("Sending packet: ");
  // Serial.println(counter);

  // // Begin packet
  // LoRa.beginPacket();
  
  // // Add message content
  // LoRa.print("Hello from Arduino ");
  // LoRa.print(counter);
  
  // // End and send packet
  // LoRa.endPacket();

  // counter++;
  
  delay(5000);  // Wait 5 seconds before sending the next message
}