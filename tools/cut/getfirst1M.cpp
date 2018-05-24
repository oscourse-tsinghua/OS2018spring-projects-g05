#include <stdio.h>
#include <stdlib.h>
#include <algorithm>
using namespace std;
#define MAXLEN 1048576

int main(int argc, char* argv[]){
	if (argc < 3){
		printf("Please specific file name that need compress\n");
		printf("Format: INPUTFILENAME OUTPUTFILENAME\n");
		return 0;
	}
	FILE *infile, *outfile;
	infile = fopen(argv[1], "rb");
	outfile = fopen(argv[2], "wb");
	if (infile == NULL){
		printf("Error: input file not exist\n");
		return 0;
	}
	unsigned char buf[MAXLEN];
	unsigned char res[MAXLEN];
	int rc;
	rc = fread(buf, sizeof(unsigned char), MAXLEN, infile);
	fwrite(buf, sizeof(unsigned char), MAXLEN, outfile);
	printf("Output file write successfully at %s\n", argv[2]);
	return 0;
}