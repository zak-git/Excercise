#include <stdio.h>
int host_x[4] = {1, 2, 3, 4};
//__constant__ int dev_x[4];
__global__ void kernel(int *d_var) {
	d_var[threadIdx.x] += 10;
	float2 f = make_float2(1.f,0.f); 
}
__global__ void init(int *d_var) { d_var[threadIdx.x] = threadIdx.x + 1; }
int main() 
{
	int data_size = 4 * sizeof(int);
	int *address;
    //cudaMalloc((void**) &dev_x, data_size);
    //cudaMemcpyToSymbol(dev_x, host_x, data_size,0, cudaMemcpyHostToDevice);
    //cudaGetSymbolAddress((void**)&address, dev_x);
	cudaMalloc((void**) &address, data_size);
	//cudaMemcpy(address, host_x, data_size, cudaMemcpyHostToDevice);
    init<<<1,4>>>(address);
    kernel<<<1,4>>>(address);
	cudaDeviceSynchronize();

	cudaMemcpy(host_x, address, data_size, cudaMemcpyDeviceToHost);

	for (int i=0; i< 4; i++){
		printf("%d\n", host_x[i]);
	}
	return 0;
}
