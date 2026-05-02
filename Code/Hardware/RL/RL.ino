#define PowEn3 A3 // 5V
#define PowEn2 7 // mb
#define PowEn1 A2 // 3.3V
#define Rl1 9
#define Rl2 A6
#define Rl3 5
void setup() {
  // pinMode(9, OUTPUT);
  //   Serial.begin(9600);
  // while (!Serial);
   
    pinMode(PowEn2, OUTPUT);
  pinMode(PowEn1, OUTPUT);
   pinMode(PowEn3, OUTPUT);

  // Bật nguồn
  digitalWrite(PowEn3, LOW); 
  // Bật nguồn
  digitalWrite(PowEn2, HIGH); 
    // Bật nguồn
  digitalWrite(PowEn1, HIGH); 
    // digitalWrite(Rl2, HIGH); // ON
;
  
}

void loop() {
   
  digitalWrite(Rl3 , HIGH); // ON
  delay(5000);

  digitalWrite(Rl3, LOW);  // OFF
  delay(5000);
  //   digitalWrite(Rl1 , HIGH); // ON
  // delay(5000);

  // digitalWrite(Rl1, LOW);  // OFF
  // delay(5000);
  //   digitalWrite(Rl2 , HIGH); // ON
  // delay(5000);

  // digitalWrite(Rl2, LOW);  // OFF
  // delay(5000);
}