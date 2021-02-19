#ifndef __FILTERING_H__
#define __FILTERING_H__

#include <utils.hpp>

double filterPixel( std::vector<std::vector<int>> image, 
                    std::vector<std::vector<double>> _distances, 
                    std::vector<double> _weights, 
                    int n, 
                    int patchSize, 
                    int pixelRow, 
                    int pixelCol, 
                    double sigma )
{
    double res = 0;
    double sumW = 0;                    // sumW is the Z(i) of w(i, j) formula
    double dist;
    std::vector<double> weights(n * n);

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            // std::cout << "pixel (" << i << ", " << j << ")" << std::endl;
            dist = util::computePatchDistance(image, _distances, _weights, n, patchSize, pixelRow, pixelCol, i, j);
            // std::cout << "distance = " << dist << std::endl;
            weights[i * n + j] = util::computeWeight(dist, sigma);
            // std::cout << "weight = " << weights[i * n + j] << std::endl << std::endl;
            sumW += weights[i * n + j];
        }
    }

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n;j++) {
            res += (weights[i * n + j] / sumW) * image[i][j];
        }
    }

    return res;
}

std::vector<double> filterImage( std::vector<std::vector<int>> image, 
                                 int n, 
                                 int patchSize,  
                                 double patchSigma,
                                 double filterSigma )
{
    std::vector<double> res(n * n);
    std::vector<std::vector<double>> _distances = util::computeDistanceMatrix(image, n);
    std::vector<double> _weights = util::computeInsideWeights(patchSize, patchSigma);

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            res[i * n + j] = filterPixel(image, _distances, _weights, n, patchSize, i, j, filterSigma);
        }
    }

    return res;
}

#endif // __FILTERING_H__