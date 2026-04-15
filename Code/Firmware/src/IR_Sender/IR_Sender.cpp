/*
 * autor: JOSEPH DREAM
 * 2020/01/17
 * website: https://josephdream.tech/
 *
 */
#include "IR_Sender.h"

IRsendRaw mySender;
// on air conditioner
uint16_t rawDataOn[RAW_DATA_LEN] = {
	4394, 4358, 550, 1618, 522, 546, 530, 1614,
	526, 1618, 526, 542, 530, 542, 526, 1618,
	526, 546, 526, 546, 526, 1614, 526, 546,
	526, 546, 526, 1618, 522, 1618, 526, 546,
	526, 1614, 526, 546, 530, 542, 526, 546,
	526, 1618, 522, 1618, 526, 1618, 522, 1622,
	522, 1618, 522, 1622, 522, 1618, 526, 1618,
	522, 550, 522, 550, 522, 546, 526, 546,
	522, 550, 522, 550, 522, 1622, 518, 550,
	522, 550, 522, 1622, 518, 550, 522, 550,
	522, 550, 518, 1626, 518, 550, 522, 1622,
	518, 1626, 514, 558, 514, 1626, 494, 1650,
	494, 1650, 490, 5206, 4358, 4394, 514, 1654,
	490, 582, 490, 1650, 494, 1650, 490, 582,
	490, 578, 494, 1650, 490, 582, 490, 582,
	490, 1650, 490, 582, 490, 582, 490, 1654,
	490, 1650, 494, 578, 490, 1630, 514, 578,
	494, 578, 494, 578, 490, 1630, 514, 1626,
	542, 1602, 538, 1606, 538, 1606, 538, 1606,
	534, 1626, 490, 1650, 494, 578, 494, 578,
	490, 578, 498, 574, 494, 578, 494, 578,
	490, 1654, 490, 578, 494, 578, 494, 1650,
	490, 578, 494, 578, 490, 582, 490, 1654,
	486, 586, 486, 1654, 490, 1654, 486, 582,
	490, 1654, 490, 1654, 486, 1654, 486, 1000};

// off air conditioner
uint16_t rawDataOff[RAW_DATA_LEN] = {
	4358, 4394, 518, 1650, 490, 578, 494, 1650,
	494, 1650, 490, 582, 490, 578, 494, 1650,
	490, 582, 490, 582, 490, 1654, 490, 578,
	494, 578, 490, 1654, 490, 1650, 494, 578,
	490, 1654, 490, 578, 494, 1650, 490, 1654,
	490, 1650, 494, 1650, 490, 582, 490, 1654,
	490, 1650, 490, 1654, 490, 578, 494, 578,
	494, 578, 494, 578, 490, 1654, 490, 578,
	494, 578, 494, 1650, 490, 1650, 494, 1650,
	490, 582, 490, 582, 490, 578, 494, 578,
	494, 578, 494, 578, 490, 582, 490, 582,
	490, 1650, 490, 1654, 490, 1650, 494, 1650,
	494, 1650, 490, 5210, 4378, 4374, 514, 1650,
	494, 578, 502, 1642, 490, 1650, 518, 554,
	518, 554, 518, 1622, 518, 554, 518, 554,
	518, 1626, 502, 566, 518, 554, 518, 1626,
	494, 1650, 490, 578, 494, 1650, 490, 582,
	490, 1630, 514, 1626, 514, 1630, 514, 1626,
	518, 578, 494, 1626, 514, 1626, 542, 1602,
	542, 554, 514, 554, 518, 554, 518, 554,
	518, 1622, 518, 554, 494, 578, 490, 1650,
	494, 1650, 490, 1650, 494, 578, 494, 578,
	494, 578, 490, 578, 494, 578, 494, 578,
	490, 582, 494, 578, 494, 1646, 494, 1650,
	490, 1650, 490, 1654, 490, 1654, 490, 1000};
void IR_sender_setup()
{
}

void IR_sender_on()
{
	Serial.println(F("IR Sender on"));
	// if (Serial.available()){
	// char command = Serial.read();
	// if (command == 'a') {
	mySender.send(rawDataOn, RAW_DATA_LEN, 40); // Pass the buffer,length, optionally frequency
	Serial.println(F("AC Switched On"));
	//  }
	//  else if (command == 'b') {
	delay(500);
	// mySender.send(rawDataOff,RAW_DATA_LEN,40);//Pass the buffer,length, optionally frequency
	// Serial.println(F("AC Switched Off"));
	// }
	// delay(500);
	//}
}
void IR_sender_off()
{
	Serial.println(F("IR Sender off"));
	mySender.send(rawDataOff, RAW_DATA_LEN, 40); // Pass the buffer,length, optionally frequency
	Serial.println(F("AC Switched Off"));
}
void IR_sender_up()
{
	Serial.println(F("IR Sender up"));
	// mySender.send(rawDataUp,RAW_DATA_LEN,40);//Pass the buffer,length, optionally frequency
	Serial.println(F("AC Temperature Up"));
}
void IR_sender_down()
{
	Serial.println(F("IR Sender down"));
	// mySender.send(rawDataDown,RAW_DATA_LEN,40);//Pass the buffer,length, optionally frequency
	Serial.println(F("AC Temperature Down"));
}