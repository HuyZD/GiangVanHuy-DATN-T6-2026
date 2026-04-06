#ifndef SPARKFUN_TSL2561_EXAMPLE_H
#define SPARKFUN_TSL2561_EXAMPLE_H

#include <Arduino.h>
#include <Wire.h>
#include <SparkFunTSL2561.h>
void TSL2561_setup();
void TSL2561_loop();
void printError(byte error);
#endif	//SPARKFUN_TSL2561_EXAMPLE_H