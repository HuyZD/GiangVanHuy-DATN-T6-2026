#include "Relay.h"
void relay_setup()
{
    Serial.println("Relay Setup");
    // Initialize relay pins as output
    pinMode(RELAY1_PIN, OUTPUT);
    pinMode(RELAY2_PIN, OUTPUT);
    pinMode(RELAY3_PIN, OUTPUT);
}
void relay1_on()
{
    Serial.println("Relay 1 ON");
    digitalWrite(RELAY1_PIN, HIGH); // Turn relay on
}
void relay1_off()
{
    Serial.println("Relay 1 OFF");
    digitalWrite(RELAY1_PIN, LOW); // Ensure relay is off
}
void relay2_on()
{
    Serial.println("Relay 2 ON");
    digitalWrite(RELAY2_PIN, HIGH); // Turn relay on
}
void relay2_off()
{
    Serial.println("Relay 2 OFF");
    digitalWrite(RELAY2_PIN, LOW); // Turn relay off
}
void relay3_on()
{
    Serial.println("Relay 3 ON");
    digitalWrite(RELAY3_PIN, HIGH); // Turn relay on
}
void relay3_off()
{
    Serial.println("Relay 3 OFF");
    digitalWrite(RELAY3_PIN, LOW); // Turn relay off
}
