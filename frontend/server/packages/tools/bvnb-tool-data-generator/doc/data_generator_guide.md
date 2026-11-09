# 🛠️ Data Generator Tool Guide

The `data_generator` tool provides synthetic data generators for numerical benchmarks and algorithm testing.

## Functions
* `GenerateUniformVector(N, MinVal, MaxVal)`: Generates `TDoubleArray` with uniform values.
* `GenerateGaussianVector(N, Mean, StdDev)`: Generates `TDoubleArray` with Box-Muller normal distribution.
* `GenerateMatrix(Rows, Cols, MinVal, MaxVal)`: Generates a 2D matrix (`T2DDoubleArray`).
* `GenerateRegressionDataset(N, Slope, Intercept, NoiseStd, out X, out Y)`: Synthetic linear regression data.
