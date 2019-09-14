#include <stdio.h>
#include <string.h>
#include <math.h>
#include <cuda_runtime.h>

__device__ char key[] = "$1&1234-1234-123456";

__device__ int f(int n, int byte, int c) {
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

__global__ void keygen(char* mathId, int hash_base, char* res) {
  res += 16*(blockIdx.x*blockDim.x+threadIdx.x);
  int hash = hash_base + blockIdx.x*blockDim.x + threadIdx.x;

  for(int byteIndex = 18; byteIndex >= 0; byteIndex--){
    hash = f(hash, (int)key[byteIndex], 0x105C3);
  }
  for(int byteIndex = 15; byteIndex >= 0; byteIndex--){
    hash = f(hash, (int)mathId[byteIndex], 0x105C3);
  }

  int n1 = 0;
  while (f(f(hash, n1 & 0xFF, 0x105C3), n1 >> 8, 0x105C3) != 0xA5B6) {
    ++n1;
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
    ++n2;
  }

  n2 = floor((n2 & 0xFFFF) * 99999.0 / 0xFFFF);

  res[10] = n1 % 10 + 48;
  res[1] = (n1/=10) % 10 + 48;
  res[6] = (n1/=10) % 10 + 48;
  res[2] = (n1/=10) % 10 + 48;
  res[3] = (n1/=10) % 10 + 48;
  res[5] = n2 % 10 + 48;
  res[0] = (n2/=10) % 10 + 48;
  res[9] = (n2/=10) % 10 + 48;
  res[11] =(n2/=10) % 10 + 48;
  res[7] = (n2/=10) % 10 + 48;
  res[4] = '-';
  res[8] = '-';
  res[12] = ':';
  res[13] = ':';
  res[14] = '1';
  res[15] = 0;
}

#if !defined Thread_Num
#define Thread_Num 1024
#endif

int main(int argc, char** argv){
  int hashStart = 0x0;
  int hashEnd   = 0x10000;

  if(argc==4){
    sscanf(argv[2],"%x",&hashStart);
    sscanf(argv[3],"%x",&hashEnd);
  }
  if(argc==3){
    sscanf(argv[2],"%x",&hashStart);
    hashEnd = hashStart + 1;
  }

  int Total_Number = hashEnd - hashStart;
  int Block_Num = (Total_Number + Thread_Num - 1)/ Thread_Num;

  char* math_id = NULL;
  size_t math_id_size = strlen(argv[1])*sizeof(char);
  cudaMalloc((void**)&math_id, math_id_size);
  cudaMemcpy(math_id, argv[1], math_id_size, cudaMemcpyHostToDevice);

  char h_res[16*Block_Num*Thread_Num];
  char* d_res = NULL;
  size_t res_size = 16*Block_Num*Thread_Num*sizeof(char);
  cudaMalloc((void**)&d_res, res_size);

  printf("Hash      MathId             Key           Password\n");

  keygen<<<Block_Num,Thread_Num>>>(math_id,hashStart,d_res);
  cudaMemcpy(h_res, d_res, 16*Total_Number*sizeof(char), cudaMemcpyDeviceToHost);
  for(int hash_del = 0; hash_del<Total_Number; hash_del++){
    printf("%04X %s 1234-1234-123456 %s\n",
            hashStart+hash_del,
            argv[1],
            h_res+16*hash_del);
  }

  return 0;
}
