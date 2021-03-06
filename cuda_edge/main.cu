#include <opencv2/opencv.hpp>
#include <stdio.h>
#include <iostream>
#include <cuda.h>
#include <cuda_runtime.h>
#define CUDA_KERNEL_LOOP(i,n) \
for(int i = blockIdx.x * blockDim.x + threadIdx.x; \
i < (n); \
i +=blockDim.x * gridDim.x)

#define CUDA_NUM_THREADS 256
#define CUDA_GET_BLOCK(n) ((n) / CUDA_NUM_THREADS + 1)


__global__ void sobel(double* data,double* sobel_x,int nums,int rows,int cols,int channels)
{
	CUDA_KERNEL_LOOP(index,nums) {
		int ch = (index % channels);
		int wh = (index / channels);
		int c = (wh % cols);
		int r = (wh / cols);
		if(c <= 1 || c >= cols - 2 || r <= 1 || r >= rows - 2)
		{
			*(sobel_x + r * cols * channels + c * channels + ch) 
				= 0;
		}
		else
		{
			double tl = *(data + (r-1) * cols * channels + (c-1) * channels + ch);
			double l = *(data + r * cols * channels + (c-1) * channels + ch);
			double bl = *(data + (r+1) * cols * channels + (c-1) * channels + ch);
			double tr = *(data + (r-1) * cols * channels + (c+1) * channels + ch);
			double ri = *(data + r * cols * channels + (c+1) * channels + ch);
			double br = *(data + (r+1) * cols * channels + (c+1) * channels + ch);
			double tmp
				= (-1) * tl + (-2) * l + (-1) * bl + tr + 2 * ri + br;
			if(tmp > 255)
					tmp = 255;
				if(tmp < 0)
					tmp = 0;
			*(sobel_x + r * cols * channels + c * channels + ch) = tmp;
		}
	}
}

cv::Mat sobel_cpu(cv::Mat im)
{
	int rows = im.rows;
	int cols = im.cols;
	int channels = im.channels();	
	int size = rows * cols * channels;
	double *sobel_x = new double[size];
	uchar* data = im.data;
	for(int r = 1; r < rows - 1; r++)
	{
		for(int c = 1; c < cols - 1; c++)
		{
			for(int ch = 0; ch < channels; ch++)
			{
				double tl = *(data + (r-1) * cols * channels + (c-1) * channels + ch);
				double l = *(data + r * cols * channels + (c-1) * channels + ch);
				double bl = *(data + (r+1) * cols * channels + (c-1) * channels + ch);
				double tr = *(data + (r-1) * cols * channels + (c+1) * channels + ch);
				double ri = *(data + r * cols * channels + (c+1) * channels + ch);
				double br = *(data + (r+1) * cols * channels + (c+1) * channels + ch);
				double tmp
					= (-1) * tl + (-2) * l + (-1) * bl + tr + 2 * ri + br;
				if(tmp > 255)
					tmp = 255;
				if(tmp < 0)
					tmp = 0;
				*(sobel_x + r * cols * channels + c * channels + ch) = tmp;
			}
		}
	}
	
	cv::Mat edge_mat(rows,cols,im.type());

	for(int r = 0; r < rows; r++)
	{
		for(int c = 0; c < cols; c++)
		{
			for(int ch = 0; ch < channels; ch++)
			{
				*(edge_mat.data + r * cols * channels + c * channels + ch)
					= *(sobel_x + r * cols * channels + c * channels + ch);
			}
		}
	}
	delete[] sobel_x;
	return edge_mat;
}
cv::Mat sobel_gpu(cv::Mat im)
{
	int rows = im.rows;
	int cols = im.cols;
	int channels = im.channels();	
	int size = rows * cols * channels;
	double* data = (double*)malloc(sizeof(double) * size);
	for(int r = 0; r < rows; r++)
	{
		for(int c = 0; c < cols; c++)
		{
			for(int ch = 0; ch < channels; ch++)
			{
				*(data + r * cols * channels + c * channels + ch)
					= *(im.data + r * cols * channels + c * channels + ch);
			}
		}
	}
	double* gpu_data;
	cudaMalloc((void**) &gpu_data,sizeof(double) * size);
	cudaMemcpy(gpu_data,data,sizeof(double) * size,cudaMemcpyHostToDevice);
	double* gpu_sobel_x;
	cudaMalloc((void**) &gpu_sobel_x,sizeof(double) * size);
	int blocks = CUDA_GET_BLOCK(size);
	sobel<<<blocks,CUDA_NUM_THREADS>>>(gpu_data,gpu_sobel_x,size,rows,cols,channels);
	cudaMemcpy(data,gpu_sobel_x,sizeof(double) * size, cudaMemcpyDeviceToHost);
	cv::Mat edge_mat(rows,cols,im.type());

	for(int r = 0; r < rows; r++)
	{
		for(int c = 0; c < cols; c++)
		{
			for(int ch = 0; ch < channels; ch++)
			{
				*(edge_mat.data + r * cols * channels + c * channels + ch)
					= *(data + r * cols * channels + c * channels + ch);
			}
		}
	}

	cudaFree(gpu_data);
	cudaFree(gpu_sobel_x);
	free(data);
	return edge_mat;
}



int main()
{
	cv::Mat im = cv::imread("/home/zak/input/lena.jpg",cv::IMREAD_GRAYSCALE);
	cv::Mat edge_map = sobel_gpu(im);
	cv::imshow("",edge_map);
	cv::waitKey();
	return 0;
}
