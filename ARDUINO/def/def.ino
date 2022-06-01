#include <IRremote.hpp>       // IR commands
#include <DHT.h>              // temp & proximity for rate
#include <DHT_U.h>            // temp & proximity for rate
#include <Wire.h>
#include "DFRobot_TCS34725.h"

#define TEMP_PIN 2
#define ECHO_PIN 9
#define TRIG_PIN 10
#define IR_PIN 12
#define LIGHT_PIN A3

// temp & proximity for rate
#define Type DHT11

DHT HT(TEMP_PIN, Type);
float tempC;
int prevRate = -1;
int newRate;

// IR commands
#define PLAY_PAUSE 0xBB44FF00
#define PREV 0xBF40FF00
#define NEXT 0xBC43FF00
#define MINVOL 0xEA15FF00
#define PLUSVOL 0xF609FF00
#define MUTE 0xB847FF00

// photoresistor for LPF
int prevLight = -1;
int light;

// rgb sensor
DFRobot_TCS34725 tcs = DFRobot_TCS34725(&Wire, TCS34725_ADDRESS, TCS34725_INTEGRATIONTIME_50MS, TCS34725_GAIN_4X);

void setup() {
  Serial.begin(9600);

  // temp & proximity for rate
  HT.begin();
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  digitalWrite(TRIG_PIN, LOW);

  // IR commands
  IrReceiver.begin(IR_PIN, true);

  // rgb sensor
  if (tcs.begin()) {
    Serial.println("Found sensor");
  } else {
    Serial.println("No RGB TCS34725 found ... check your connections");
    while (1); // halt!
  }
}

void loop() {
  // photoresistor
  light = analogRead(LIGHT_PIN);
  light /= 10.24; // / fullscale * 100 per inviare interi
  if (light != prevLight || prevLight == -1) {
    // send only if its new
    Serial.print(light);
    Serial.println("L");
    prevLight = light;
  }

  // temp & proximity for rate
  tempC = HT.readTemperature();
  // Serial.println(tempC);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  unsigned long tempo = pulseIn(ECHO_PIN, HIGH);
  float velocita = 0.03314 + 0.000062 * tempC;
  float proximity = velocita * tempo / 2;
  if (proximity >= 30.0) {
    proximity = 30.0; // max 30 cm
  }
  newRate = ((proximity / 30.0) * 2) * 100; // maps 0-30 cm to [0,200]
  newRate = (newRate / 25) * 25 + 25;
  if (newRate > 200) {
    newRate = 200;
  } else if (newRate < 50) {
    newRate = 50;
  }

  if (newRate != prevRate || prevRate == -1) {
    Serial.print(newRate);
    Serial.print("D");
    prevRate = newRate;
  }

  if (IrReceiver.decode()) {
    //Serial.println(IrReceiver.decodedIRData.decodedRawData, HEX);
    //IrReceiver.printIRResultShort(&Serial); // optional use new print version

    switch (IrReceiver.decodedIRData.decodedRawData) {
      case PLAY_PAUSE:
        Serial.println("P");
        break;
      case PREV:
        Serial.println("<");
        break;
      case NEXT:
        Serial.println(">");
        break;
      case MINVOL:
        Serial.print("-");
        break;
      case PLUSVOL:
        Serial.print("+");
        break;
      case MUTE:
        Serial.print("M");
        break;
    }

    IrReceiver.resume(); // Enable receiving of the next value
  }
  
  uint16_t clear, red, green, blue;
  tcs.getRGBC(&red, &green, &blue, &clear);
  // turn off LED
  // tcs.lock();
  Serial.print(red);    Serial.print("R");
  Serial.print(green);  Serial.print("G");
  Serial.print(blue);   Serial.print("B");

  delay(200);

}
