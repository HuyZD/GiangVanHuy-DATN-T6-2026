#include <SPI.h>
#include <ModbusMaster.h>
#define MAX485_CONTROL 4 

ModbusMaster node;
void preTransmission() {
  digitalWrite(MAX485_CONTROL, HIGH);
}

// chuyển sang chế độ nhận
void postTransmission() {
  digitalWrite(MAX485_CONTROL, LOW);
}
void RS485_Sensor_setup() {


    pinMode(MAX485_CONTROL, OUTPUT);
  digitalWrite(MAX485_CONTROL, LOW);

  node.begin(1, Serial); // 👈 dùng Serial thay vì rs485

  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);
}

void RS485_Sensor_read(float &temperature1, float &humidity) {
    uint8_t result;

  result = node.readHoldingRegisters(0x0300, 2);

  if (result == node.ku8MBSuccess) {

    uint16_t temp_raw = node.getResponseBuffer(0);
    uint16_t hum_raw  = node.getResponseBuffer(1);

     temperature1 = temp_raw / 10.0;
     humidity    = hum_raw / 10.0;

  } 

}