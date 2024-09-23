#include "wramp.h"
int counter = 0;
char c;
/**
 * Main.
 **/
void serial_main() {

    int format = 1;                                         
	//Infinite loop
	while(1) {
        counter++;                                                  // Increment counter
        c = recieveCharacter();                                     // Recieve the character from serial port 2 to select format

        if (format == 1){                                           // If the format selected is 1, print the number of interrupts
            printCounter('\r');
            printCounter(((counter / 100000) % 10) + 48);
            printCounter(((counter / 10000) % 10) + 48);
            printCounter(((counter / 1000) % 10) + 48);
            printCounter(((counter / 100) % 10) + 48);
            printCounter(((counter / 10) % 10) + 48);
            printCounter((counter % 10) + 48);
            printCounter(' ');
        }
        if (format == 2){                                           // If the format selected is 2, print the counter in minutes and seconds
            int seconds = counter / 100;
            int minutes = seconds / 60;
            seconds = seconds % 60;
            printCounter('\r'); 
            printCounter(((minutes / 10) % 10) + 48);
            printCounter((minutes % 10) + 48);
            printCounter(':');
            printCounter(((seconds / 10) % 10) + 48);
            printCounter((seconds % 10) + 48);
            printCounter(' ');
            printCounter(' ');
        }
        if (format == 3){                                           // If the format selected is 3, print the counter in terms of seconds, with 2 decimal places
            int seconds = counter / 100;
            printCounter('\r'); 
            printCounter(((seconds / 1000) % 10) + 48);
            printCounter(((seconds / 100) % 10) + 48);
            printCounter(((seconds / 10) % 10) + 48);
            printCounter((seconds % 10) + 48);
            printCounter('.');
            printCounter(((seconds / 10) % 10) + 48);
            printCounter((seconds % 10) + 48);

        }

        if(c == '1') format = 1;                                    // If '1' is typed into serial port 2, change format to 1
        else if (c == 'q') break;                                   // If 'q' is typed into serial port 2, exit program
        else if (c == '2') format = 2;                              // If '2' is typed into serial port 2, change format to 2
        else if (c == '3') format = 3;                              // If '3' is typed into serial port 2, change format to 3
            
	}
}
// Recieves character from serial port 2
int recieveCharacter(){
    //Loop while the RDR bit is not set
	if(!(WrampSp2->Stat & 1));
    return WrampSp2->Rx;
}
// Prints the counter to serial port 2 in digits
void printCounter(char c) {
	//Loop while the TDR bit is not set
    while(!(WrampSp2->Stat & 2));
    WrampSp2->Tx = c;
}
