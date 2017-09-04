//***************************************************************************
//
//    7-Segment LED counter/timer sign.
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
* This is a simple test app that controls a single-digit on a 7-segment display
* that is build using 2-LED NeoPixel strips.
*
* Arduino I/O configuration:
*
* - D6 = LED strip DI (Data In)
* .
************************************************************************************/

/**
* 
* I/O configuration:
*
* D6 = LED strip DI (Data In)
*
************************************************************************************/

#include <Adafruit_NeoPixel.h>

#define LED_STRIP_PIN  (6)


/**
* A 7-segment LED descriptor used to identify its starting LED address and the
* number of LEDs in the digit.
*
* @warning Change the data types to uint16_t if you have more than 256 LEDs.
************************************************************************************/
struct ledSescriptor_t
{
  uint8_t    startingLedNumber;    // the address of the first LED in a digit
  uint8_t    numStrips;            // number of strips per segment
  uint8_t    ledsPerStrip;         // number of LEDs per strip
};

/**
* One descriptor for each LED in the sign
************************************************************************************/
struct ledSescriptor_t descriptors[] =
{
  {0, 1, 2},     // small 1/10th digit 
  {14 ,2, 5},    // seconds LSD
  {84, 2, 5},    // seconds MSD
  {156, 2, 5},   // minutes LSD
  {226, 2, 5}    // minutes MSD
};

static const uint8_t colon1 = 154;  // the address of the first colon LED
static const uint8_t colon2 = 155;  // the address of the second colon LED

#define NUM_LEDS  (296)  // sizeof(descriptors)/sizeof(descriptors[0]))

// Tell the NeoPixel library how many LEDs we will be using
static Adafruit_NeoPixel LEDstrip(NUM_LEDS, LED_STRIP_PIN, NEO_GRB + NEO_KHZ800);



static volatile uint32_t myclock = 0;  // The current 10HZ timer/counter value.


/**
* Initialize things.
*************************************************************************************/
void setup() 
{
  LEDstrip.begin();
  LEDstrip.show(); // No colors set yet.  So this will set all pixels to 'off'.

  // initialize serial communication (for debugging)
  //Serial.begin(115200);
  
  counterReset();
  
  initTimer();
}


/**
* Initialize timer-1 to operate in CTC mode to operate at 10HZ.
*************************************************************************************/
void initTimer()
{
  // Do a google search on: arduino timer1 interrupt example for more details on this.
  
  cli();                   // disable all interrupts
  
  TCCR1A = 0;
  TCCR1B = 0;
  TCNT1 = 0;
  OCR1A = 6249;            // compare match register 16MHz/256/10Hz - 1
  TCCR1B |= (1 << WGM12);  // CTC mode
  TCCR1B |= (1 << CS12);   // 256 prescaler
  TIMSK1 |= (1 << OCIE1A); // enable timer compare interrupt
  
  sei();                   // enable all interrupts
}


/**
* When timer-1 expires (10 times per second) this interrupt handler is called.
*************************************************************************************/
ISR(TIMER1_COMPA_vect) // timer compare interrupt service routine
{
  ++myclock;    // increment the clock counter
}




/** @brief The 'next' time to 'tick' the clock counter. */
static uint32_t next=0;    // the 'next' time to 'tick' the clock counter

/** @brief The number of 'ticks' since the system was started. */
static uint32_t ctr=0;     // the number of 'ticks' since the system was started


/**
* Reset the timer 'tick' and 'next' values, effectively restting the timer display.
*************************************************************************************/
void counterReset()
{
  next = 0;           // prime the counter logic to start immediately
  //ctr = 60L*60*10;    // one hour (need L else get a 32 bit int :-/
  ctr = 3*60*10;      // 3 minutes
  //ctr = 6*10;         // 6 seconds
}

/** @brief The brightness (luminosity) of the LEDs (0=black, 255=bright) */
#define LUMA  255
//#define LUMA  127
//#define LUMA  63

/** @brief A dash character code. */
#define DASH_CHARACTER  (16)

/** @brief The black color. */
static const uint32_t blackColor = Adafruit_NeoPixel::Color(0, 0, 0); 

/** @brief The black color used for timer EXPIRED indicator. */
static const uint32_t redColor = Adafruit_NeoPixel::Color(LUMA, 0, 0); 

/** @brief The foreground (on) color to use for the 2-strip LEDs. */
static const uint32_t fg2 = Adafruit_NeoPixel::Color(LUMA/4, LUMA/2, 0);
  
/** @brief The foreground (on) color to use for the 1-strip LEDs. */
static const uint32_t fg1 = Adafruit_NeoPixel::Color(LUMA/3, LUMA, 0);


/**
* @brief Main processing loop.
*
* If enough time has passed to update the display:
* - advance the counter
* - display the new value
* - calculate the time for the next timer-tick 
*
* @note The millis function will wrap around every 49 days.  So if you want to 
*  use it for longer than that period, you will want to change the logic used to
*  determine 100 milliseconds have passed.
*************************************************************************************/
void loop() 
{
  static const unsigned long tperiod=1;//100;    // millis per tick
  static uint32_t pattern = 0;

  //uint32_t now = millis();

  cli(); // disable all interrupts
  uint32_t now = myclock;        // Do this with IRQs off in case the assignment is not atomic!
  sei(); // enable all interrupts

  if (now >= next)
  {
    next = next+tperiod;

    if (ctr == 0)
    {
      // when the count is zero, display a special DONE pattern of red dashes
      ++pattern;

      if (pattern%2 != 0)
      {
        uint32_t color = (pattern/2)%8==0 ? blackColor : redColor;

        // show a bunch of dashes
        digit(DASH_CHARACTER, 4, color);
        digit(DASH_CHARACTER, 3, color);
        digit(DASH_CHARACTER, 2, color);
        digit(DASH_CHARACTER, 1, color);
        digit(DASH_CHARACTER, 0, blackColor);
        
        LEDstrip.setPixelColor(colon1, blackColor);    // turn on the colon dots
        LEDstrip.setPixelColor(colon2, blackColor);      
      }
    }
    else
    {
      --ctr;
      
      uint8_t t = ctr%10;
      uint8_t ss = (ctr/10)%60;
      uint8_t mm = (ctr/600)%60;
      
      digit(mm/10, 4, mm/10 ? fg2 : blackColor);  // blank the leading zero
      digit(mm%10, 3, fg2);
      digit(ss/10, 2, fg2);
      digit(ss%10, 1, fg2);
      digit(t, 0, fg1);
      
      LEDstrip.setPixelColor(colon1, fg1);    // turn on the colon dots
      LEDstrip.setPixelColor(colon2, fg1);      
    }
    LEDstrip.show();  // Flush the settings to the LEDs
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
* The most significant bit is not used.
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
* @param place The place value (position) to display the digit
* @param c The color of the segment to use.
*
* @warning This supports 1 or 2 strips per LED.  Supprt for 3 or more strips
*  is left as a task for the reader.  Hint: add a loop to calculate the value
*  for 13-k by using the strip number.
*************************************************************************************/
void digit(uint8_t i, uint16_t place, uint32_t c)
{
  uint8_t v = font[i];  // which segments are to be lit for the given digit value
  uint16_t startingLed = descriptors[place].startingLedNumber;  // first LED in the digit's 7seg LED
  uint8_t lps = descriptors[place].ledsPerStrip;                // number of LEDs in each strip of the digit
  uint8_t ns = descriptors[place].numStrips;                    // number of strips in each segment of the digit
  
  for(uint8_t k=0; k<7; ++k)
  {
    seg(startingLed+k*lps, lps, v&0x01 ? c : blackColor);  // set to black or color depending on the font

    if (ns == 2)
      seg(startingLed+(13-k)*lps, lps , v&0x01 ? c : blackColor);
  
    v >>= 1;
  }
}


/**
* @brief A utility function to set the color of a sequence of LEDs.
*
* @param startingLed The first LED address to set.
* @param qty The total number of LEDs in the consecutive sequence to set.
* @param c The color value to which the LEDs will be set.
*************************************************************************************/
void seg(uint16_t startingLed, uint16_t qty, uint32_t c)
{
  uint16_t last = startingLed+qty;
  
  while (startingLed < last)
  {
    LEDstrip.setPixelColor(startingLed, c);
    ++startingLed;
  }
}
