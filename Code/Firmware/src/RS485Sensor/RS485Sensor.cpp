#include "RS485Sensor.h"

SoftwareSerial rs485(10, 11); // RX, TX
ModbusMaster node;

// chuyển sang chế độ gửi
void preTransmission() {
  digitalWrite(MAX485_CONTROL, HIGH);
}

// chuyển sang chế độ nhận
void postTransmission() {
  digitalWrite(MAX485_CONTROL, LOW);
}

void RS485_Sensor_setup() {
  rs485.begin(9600);      

  pinMode(MAX485_CONTROL, OUTPUT);
  digitalWrite(MAX485_CONTROL, LOW); 

  node.begin(1, Serial); 

  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);
}

void RS485_Sensor_read() {
  uint8_t result;

  // đọc 2 thanh ghi từ địa chỉ 0
  result = node.readHoldingRegisters(0x0300, 2);

  if (result == node.ku8MBSuccess) {
    uint16_t temp_raw = node.getResponseBuffer(0);
    uint16_t hum_raw  = node.getResponseBuffer(1);

    float temperature = temp_raw / 10.0;
    float humidity    = hum_raw / 10.0;

    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.println(" C");

    Serial.print("Humidity: ");
    Serial.print(humidity);
    Serial.println(" %");
  } else {
    Serial.print("Error code: ");
    Serial.println(result);
  }

  delay(1000);
}