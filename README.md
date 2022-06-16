# OnlineLogBinning

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://meese-wj.github.io/OnlineLogBinning.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://meese-wj.github.io/OnlineLogBinning.jl/dev)
[![Build Status](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml?query=branch%3Amain)

Julia package to determine effective number of uncorrelated data points in a correlated data stream via an `O(log N)` online binning algorithm.

This package uses the online logarithmic binning algorithm discussed in Refs. [[1]](@ref) and [[2]](@ref), but uses the numerically stable _first-pass pairwise_ algorithm from Ref. [[3]](@ref) to update the mean and variance accumulators. Importantly, the binning analysis is _online_ in the sense that the whole data stream of size `O(N)` need not be stored. Instead, a much smaller data stream of size `O(log N)` needs to be. This makes properly assessing the correlated errors generated from Markov Chain Monte Carlo simulations practical to update _on-the-fly_ [[4]](@ref). 

# See Also

1. [`BinningAnalysis.jl`](https://github.com/carstenbauer/BinningAnalysis.jl) for a very similar Julia package which served as an inspiration for this one. Our package does not have as broad of a scope as theirs.
    * One of the authors of [`BinningAnalysis.jl`](https://github.com/carstenbauer/BinningAnalysis.jl) also wrote Ref. [[4]](@ref) which gives a great introduction to the statistical analysis of Monte Carlo data.

1. [`OnlineStats.jl`](https://github.com/joshday/OnlineStats.jlhttps://github.com/joshday/OnlineStats.jl) for many more online statistics and routines, most of which are beyond the scope of this package.

# References

<a id="1">[1]</a>
See Section D of M. Wallerberger's _Efficient estimation of autocorrelation spectra_ (2018) at [arXiv:1810.05079](https://arxiv.org/pdf/1810.05079.pdf).

<a id="2">[2]</a>
Ambegaokar, V. and Troyer, M. _Estimating errors reliably in Monte Carlo simulations of the Ehrenfest model_, American Journal of Physics __78__, 150-157 (2010) [doi.org/10.1119/1.3247985](https://doi.org/10.1119/1.3247985)

<a id="3">[3]</a>
Chan, T. F., Golub, G. H., & LeVeque, R. J. (1983). _Algorithms for Computing the Sample Variance: Analysis and Recommendations_. The American Statistician, __37__(3), 242–247. [doi.org/10.2307/2683386](https://doi.org/10.2307/2683386)

<a id="4">[4]</a>
Bauer, C. _Simulating and machine learning quantum criticality in a nearly antiferromagnetic metal_. PhD Dissertation, 2020. Specifically [Section 2.6](http://www.thp.uni-koeln.de/trebst/thesis/PhD_CarstenBauer.pdf).
