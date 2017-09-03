//***************************************************************************
//
//    7-Segment LED counter/timer sign single-digit test proggie.
//
//
//    COPYRIGHT (C) 2017 JOHN WINANS
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//    Get your copy from here:
//
//       https://github.com/johnwinans/7SegLED
//
//***************************************************************************

/** @file
*
* This is a simple test app that controls a single-digit on a single-strip 
* 7-segment display with 2 LEDs per strip.
*
* Arduino I/O configuration:
*
* - D6 = LED strip DI (Data In)
* .
************************************************************************************/

#include <Adafruit_NeoPixel.h>

/** @brief The pin number connected to the LED DI signal. */
#define LED_STRIP_PIN  (6)

/** @brief The gross number of LEDs in the daisy-chain of all strips. */
#define NUM_LEDS (14)

/** @brief The one and only daisy-chain of all the LED strips. */
static Adafruit_NeoPixel LEDstrip(NUM_LEDS, LED_STRIP_PIN, NEO_GRB + NEO_KHZ800);


/** 
* @brief Inialize everything
*
* - Create Adafruit_NeoPixel(), initialize it and call show() to clear all the LEDs.
* - Reset the counter to 0.
* .
*************************************************************************************/
void setup() 
{
  LEDstrip.begin();   // one-time strip setup
  LEDstrip.show();    // No colors set yet.  So this will set all pixels to 'off'.

  // initialize serial communication
  //Serial.begin(115200);
  
  counterReset();
}


/** @brief The 'next' time to 'tick' the clock counter. */
static uint32_t next;    

/** @brief The number of 'ticks' since the system was started. */
static uint32_t ctr;


/**
* @brief Reset the timer 'tick' and 'next' values, effectively restting the 
* timer display.
*************************************************************************************/
static void counterReset()
{
  next = millis();    // prime the counter logic to start immediately
  ctr = 0;
}



/** @brief The brightness (luminosity) of the LEDs */
#define LUMA  255
//#define LUMA  127
//#define LUMA  63

/** @brief The foreground (on) color to use for the LEDs. */
static const uint32_t fg = Adafruit_NeoPixel::Color(0, LUMA*.25, LUMA);  

/** @brief The background (off) color for the LEDs. */
static const uint32_t bg = Adafruit_NeoPixel::Color(0, 0, 0);



/** 
* @brief Main processing loop.
*
* If enough time has passed to update the display:
* - advance the counter
* - display the new value
* - calculate the time for the next timer-tick 
*************************************************************************************/
void loop() 
{
  static const unsigned long tperiod=1000;                  // millis per 'timer-tick

  uint32_t now = millis();    // what time is it right now?

  if (now >= next)            // if 'now' is the time to update the display...
  {
      digit(ctr%17, fg);      // set the LED values to display a digit
      
      LEDstrip.show();        // flush the data to the LED strip

      next = next+tperiod;    // determine the next time to update the display
      ++ctr;                  // advance the count value used for the display
  }
}



/**
* @brief A 7-Segment display 'font'.
*
* This is the font used to convert the values from 0-F into a displayable
* character on a 7-segment display.  There is one value for each character.
*
* The relationship of the font bit positions to the LED display segments:
*
@verbatim
   --1--
  |     |
  2     0
  |     |
   --3--
  |     |
  6     4
  |     |
   --5--
@endverbatim
*
* For example: In order to display the number '1', the #0 and #4 segments need to be
* turned on and the rest turned off.  Therefore the binary value 0010001 
* (hex 0x11) represents the segment values to display a '1'.
*
* The most significant bit is not used and is set to zero here.
*************************************************************************************/
static const uint8_t font[] =
{
  0b01110111,  // 0
  0b00010001,  // 1
  0b01101011,  // 2
  0b00111011,  // 3
  0b00011101,  // 4
  0b00111110,  // 5
  0b01111110,  // 6
  0b00010011,  // 7
  0b01111111,  // 8
  0b00111111,  // 9
  0b01011111,  // A
  0b01111100,  // b
  0b01100110,  // C
  0b01111001,  // d
  0b01101110,  // E
  0b01001110,  // F
  0b00001000   // - (a dash symbol)
};


/**
* @brief Set the value for a digit.
*
* @param i The hex digit value to value to display
* @param c The color of the segment to use.
*************************************************************************************/
static void digit(uint8_t i, uint32_t c)
{
  static const uint8_t lps = 2;          // The number of LEDs per strip

  uint8_t v = font[i];      // use the font to determine which segments will be on and off
  
  for(uint8_t k=0; k<7; ++k)             // iterate once per LED segment
  {
    seg(k*lps, lps, v&0x01 ? c : bg);    // set all LEDs in one segment to 'on' or 'off'
    v >>= 1;                             // prepare to display the 'next' segment
  }
}


/**
* @brief A utility function to set the color of a sequence of LEDs.
*
* @param startingLed The first LED address to set.
* @param qty The total number of LEDs in the consecutive sequence to set.
* @param c The color value to which the LEDs will be set.
*************************************************************************************/
static void seg(uint16_t startingLed, uint8_t qty, uint32_t c)
{
  uint8_t last = startingLed+qty;            // one more than the last LED address in the range to set
  
  while (startingLed < last)                 // for each LED in the range of addresses...
  {
    LEDstrip.setPixelColor(startingLed, c);  // set the LED's color
    ++startingLed;                           // advance to the next LED
  }
}
