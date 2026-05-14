/* rawR&cv.ino Example sketch for IRLib2
 *  Illustrate how to capture raw timing values for an unknow protocol.
 *  You will capture a signal using this sketch. It will output data the
 *  serial monitor that you can cut and paste into the "rawSend.ino"
 *  sketch.
 */
#include "IR_Receiver.h"
IRrecvPCI myReceiver(2); // pin number for the receiver

void IR_receiver_setup()
{
  Serial.println(F("IR Receiver setup"));
  myReceiver.enableIRIn(); // Start the receiver
  Serial.println(F("Ready to receive IR signals"));
  myReceiver.setFrameTimeout(100000);
}

void IR_receiver()
{
 // Serial.println(F("IR Receiver"));
  // Continue looping until you get a complete signal received
  if (myReceiver.getResults())
  {
    const bufIndex_t rawLength = recvGlobal.recvLength;

    Serial.println(F("Do a cut-and-paste of the following lines into the "));
    Serial.println(F("designated location in rawSend.ino"));
    Serial.print(F("\n#define RAW_DATA_LEN "));
    Serial.println(rawLength, DEC);
    Serial.print(F("uint16_t rawData[RAW_DATA_LEN]={\n\t"));
    for (bufIndex_t i = 1; i < rawLength; i++)
    {
      Serial.print(recvGlobal.recvBuffer[i], DEC);
      Serial.print(F(", "));
      if ((i % 8) == 0)
        Serial.print(F("\n\t"));
    }
    Serial.println(F("1000};")); // Add arbitrary trailing space
    myReceiver.disableIRIn();
    delay(200);
    myReceiver.enableIRIn();     // Restart receiver
    Serial.println(F("Ready to receive IR signals"));
  }
}
