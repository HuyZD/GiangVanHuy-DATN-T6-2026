#ifndef SCD40_H
#define SCD40_H

#include <Arduino.h>
#include <Wire.h>
#include <SensirionI2cScd4x.h>
void SCD40_setup();
float SCD40_read();

#endif	//SCD40_H   