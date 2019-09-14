#include <stdio.h>
#include <math.h>

const char key[] = "$1&1234-1234-123456";

int f(int n, int byte, int c) {
  for (int bitIndex = 0; bitIndex <= 7; bitIndex++) {
    int bit = (byte >> bitIndex) & 1;
    if (bit + ((n - bit) & ~1) == n) {
      n = (n - bit) >> 1;
    } else {
      n = ((c - bit) ^ n) >> 1;
    }
  }
  return n;
}

char* g(char* mathId, int hash, char* res) {
  for(int byteIndex = 18; byteIndex >= 0; byteIndex--){
    hash = f(hash, (int)key[byteIndex], 0x105C3);
  }
  for(int byteIndex = 15; byteIndex >= 0; byteIndex--){
    hash = f(hash, (int)mathId[byteIndex], 0x105C3);
  }

  int n1 = 0;
  while (f(f(hash, n1 & 0xFF, 0x105C3), n1 >> 8, 0x105C3) != 0xA5B6) {
    if (++n1 >= 0xFFFF) {
      return "";
    }
  }

  n1 = floor(((n1 + 0x72FA) & 0xFFFF) * 99999.0 / 0xFFFF);
  int temp = n1/1000*1000 + n1%100*10 + n1%1000/100;
  temp = ceil((temp/99999.0)*0xFFFF);
  temp = f(f(0, temp & 0xFF, 0x1064B), temp >> 8, 0x1064B);

  for(int byteIndex = 18; byteIndex >= 0; byteIndex--){
    temp = f(temp, (int)key[byteIndex], 0x1064B);
  }
  for(int byteIndex = 15; byteIndex >= 0; byteIndex--){
    temp = f(temp, (int)mathId[byteIndex], 0x1064B);
  }

  int n2 = 0;
  while (f(f(temp, n2 & 0xFF, 0x1064B), n2 >> 8, 0x1064B) != 0xA5B6) {
    if (++n2 >= 0xFFFF) {
      return "";
    }
  }

  n2 = floor((n2 & 0xFFFF) * 99999.0 / 0xFFFF);

  char n1str[6];
  sprintf(n1str,"%05d",n1);
  char n2str[6];
  sprintf(n2str,"%05d",n2);

  res[0] = n2str[3];
  res[1] = n1str[3];
  res[2] = n1str[1];
  res[3] = n1str[0];
  res[4] = '-';
  res[5] = n2str[4];
  res[6] = n1str[2];
  res[7] = n2str[0];
  res[8] = '-';
  res[9] = n2str[2];
  res[10] = n1str[4];
  res[11] = n2str[1];
  res[12] = ':';
  res[13] = ':';
  res[14] = '1';
  res[15] = 0;

  return res;
}

int main(int argc, char** argv){
  int hashStart = 0x0;
  int hashEnd   = 0xFFFF;
  if(argc==4){
    sscanf(argv[2],"%x",&hashStart);
    sscanf(argv[3],"%x",&hashEnd);
  }
  if(argc==3){
    sscanf(argv[2],"%x",&hashStart);
    hashEnd = hashStart + 1;
  }
  char res[16];
  printf("Hash      MathId             Key           Password\n");
  for(int hash = hashStart; hash<hashEnd; hash++)
    printf("%04X %s 1234-1234-123456 %s\n",hash,argv[1],g(argv[1],hash,res));
  return 0;
}
