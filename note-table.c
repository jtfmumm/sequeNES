#include <stdio.h>
#include <math.h>
#include <string.h>

char *NOTE_NAMES[17] = {"C", "Cs", "Db", "D", "Ds", "Eb", "E", "F", "Fs", "Gb", "G", "Gs", "Ab", "A", "As", "Bb", "B"};
int OCTAVES = 8;
//int nextNote(int);

int main()
{
	int i;
	char padding = '0';
	int octave = 1;
	int curNote = 13;
	printf(";Octave 1\n");
	//char *thisOne = &curNote[0];
	for(i = 0; i < (OCTAVES * 11); i++) {
		if (i == 16)
			padding = '\0'; //Switch padding off for two digit hex numbers 
		
		printf("%s%d = $%c%X\n", NOTE_NAMES[curNote], octave, padding, i);
		
		if (NOTE_NAMES[curNote][1] == 's') {
			curNote++;
			printf("%s%d = $%c%X\n", NOTE_NAMES[curNote], octave, padding, i);			
		}
		
		curNote++;
		//Loop around NOTE_NAMES array
		if (curNote == 17) {
			octave++;
			printf("\n;Octave %d\n", octave);
			curNote = 0;
		}
	}
	return 0;
}

