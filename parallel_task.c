#include "wramp.h"

/**
 * Main.
 **/
void parallel_main() {
	//Variables must be declared at the top of a block
	int switches = 0;
    int buttons = 0;
    int currentButton = 1;
	
	//Infinite loop
	while(1) {
	    switches = WrampParallel->Switches;                             // Read current value from parallel switch register
        buttons = WrampParallel->Buttons;                               // Record button press 
        if(buttons == 0x4 & buttons != 0x2 & buttons != 0x1){           // If button pressed was button 2, and no otheer putton was pressed set the current button to 3
            currentButton = 3;
        }
        else if(buttons == 0x1 & buttons != 0x4 & buttons != 0x2){      // If button pressed was button 0, and no otheer putton was pressed set the current button to 1
            currentButton = 1;
        }
        else if(buttons == 0x2 & buttons != 0x4 & buttons != 0x1){      // If button pressed was button 1, and no otheer putton was pressed set the current button to 2
            currentButton = 2;
        }
        else if(currentButton == 3){                                    // If current button == 3 (button 2 pressed) exit the program
            break;
        }
        else if(currentButton == 1){                                    // If current button == 1 (button 0 pressed) write decimal values to ssd
            writeDecimal(switches);
        }
        else if(currentButton == 2){                                    // If current button == 2 (button 1 pressed) write hexadecimal values to ssd
            writeHexadecimal(switches);
        }
	}
}

void writeDecimal(int value){                                           // Extract button value into digits and print to sdd as decimal values
    int ones = value % 10;
    int tens = (value / 10) % 10;
    int hundreds = (value / 100) % 10;
    int thousands = (value / 1000) % 10;

    WrampParallel->UpperLeftSSD = thousands;
    WrampParallel->UpperRightSSD = hundreds;
    WrampParallel->LowerLeftSSD = tens;
    WrampParallel->LowerRightSSD = ones;
}

void writeHexadecimal(int value){                                       // Extract button value into digits and print to sdd as hexadecimal values
    int firstSSD = value & 0x000f; 
    int secondSSD = (value & 0x00f0) >> 4;
    int thirdSSD = (value & 0x0f00) >> 8;
    int fourthSSD = (value & 0xf000) >> 12;

    WrampParallel->UpperLeftSSD = fourthSSD;
    WrampParallel->UpperRightSSD = thirdSSD;
    WrampParallel->LowerLeftSSD = secondSSD;
    WrampParallel->LowerRightSSD = firstSSD;
}


