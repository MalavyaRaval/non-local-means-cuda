#ifndef __CUDAFILTERING_CUH__
#define __CUDAFILTERING_CUH__

#include <utils.cuh>

__global__ void computeWeights( float *image,
    float *_weights,
    int n,
    int patchSize,
    int patchRowStart,
    int patchColStart,
    float sigma,
    float *weights,
    float *temp)
{

    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if (index >= n * n){
        return;
    }
    int row = index / n;
    int col = index % n;

    float dist = util::computePatchDistance(  image, 
                        _weights, 
                        n, 
                        patchSize, 
                        patchRowStart, 
                        patchColStart, 
                        row - patchSize / 2, 
                        col - patchSize / 2  );
    weights[index] =  util::computeWeight(dist, sigma);

    *temp = dist;

}

float cudaFilterPixel( float * image, 
                    float * _weights, 
                    int n, 
                    int patchSize, 
                    int pixelRow, 
                    int pixelCol, 
                    float sigma )
{
    float res = 0;
    float sumW = 0;                    // sumW is the Z(i) of w(i, j) formula

    std::vector<float > weights(n * n);
    int patchRowStart = pixelRow - patchSize / 2;
    int patchColStart = pixelCol - patchSize / 2;

    float *d_image, *d_insideWeights, *d_weights;
    int size_image = n * n * sizeof(float );
    int size_insideWeights = patchSize * patchSize * sizeof(float );

    // Alloc space for device copies of a, b, c
    cudaMalloc((void **)&d_image, size_image);
    cudaMalloc((void **)&d_insideWeights, size_insideWeights);
    cudaMalloc((void **)&d_weights, size_image);
    
    cudaMemcpy(d_image, image, size_image, cudaMemcpyHostToDevice);
    cudaMemcpy(d_insideWeights, _weights, size_insideWeights, cudaMemcpyHostToDevice);

    float *d_temp;
    cudaMalloc((void **)&d_temp, sizeof(float ));
    

    computeWeights<<<n,n>>>(    d_image,
                                d_insideWeights,
                                n,
                                patchSize,
                                patchRowStart,
                                patchColStart,
                                sigma,
                                d_weights,
                                d_temp);

    cudaMemcpy(weights.data(), d_weights, size_image, cudaMemcpyDeviceToHost);
    
    float temp;
    cudaMemcpy(&temp, d_temp, sizeof(float ), cudaMemcpyDeviceToHost);

    // std::cout << temp << std::endl;

    // exit(1);
    cudaFree(d_image); cudaFree(d_insideWeights); cudaFree(d_weights);

    for(int i = 0; i < n * n; i++){
        sumW += weights[i];
    }

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            res += (weights[i * n + j] / sumW) * image[i * n + j];
        }
    }

    return res;
}

std::vector<float > cudaFilterImage( float * image, 
                                 int n, 
                                 int patchSize,  
                                 float patchSigma,
                                 float filterSigma )
{
    std::vector<float > res(n * n);
    // std::vector<float > _distances = util::computeDistanceMatrix(image, n);
    std::vector<float> tempVec = util::computeInsideWeights(patchSize, patchSigma);
    float * _weights = tempVec.data();

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            res[i * n + j] = cudaFilterPixel(image, _weights, n, patchSize, i, j, filterSigma);
        }
    }

    return res;
}

#endif // __CUDAFILTERING_CUH__