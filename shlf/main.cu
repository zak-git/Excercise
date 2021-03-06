#include <stdio.h>

typedef struct __align__(4)
{
	double b;
    float a;
} point;

__global__ void testKernel(point *p)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    p[i].a = 1.1;
    p[i].b = 2.2;
}

int main(void)
{
        // set number of points 
    int numPoints    = 16,
        gpuBlockSize = 4,
        pointSize    = sizeof(point),
        numBytes     = numPoints * pointSize,
        gpuGridSize  = numPoints / gpuBlockSize;
	printf("%d\n",pointSize);
        // allocate memory
    point *cpuPointArray = new point[numPoints],
          *gpuPointArray;
    cpuPointArray = (point*)malloc(numBytes);
    cudaMalloc((void**)&gpuPointArray, numBytes);

        // launch kernel
    testKernel<<<gpuGridSize,gpuBlockSize>>>(gpuPointArray);

        // retrieve the results
    cudaMemcpy(cpuPointArray, gpuPointArray, numBytes, cudaMemcpyDeviceToHost);
    printf("testKernel results:\n");
    for(int i = 0; i < numPoints; ++i)
    {
        printf("point.a: %f, point.b: %f\n",cpuPointArray[i].a,cpuPointArray[i].b);
    }

        // deallocate memory
    free(cpuPointArray);
    cudaFree(gpuPointArray);

    return 0;
}
