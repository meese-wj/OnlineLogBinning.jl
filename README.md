# OnlineLogBinning

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://meese-wj.github.io/OnlineLogBinning.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://meese-wj.github.io/OnlineLogBinning.jl/dev)
[![Build Status](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml?query=branch%3Amain) 

Julia package to determine effective number of uncorrelated data points in a correlated data stream via an `O(log N)` online binning algorithm.

This package uses the online logarithmic binning algorithm discussed in Refs. [[1]](@ref) and [[2]](@ref), but uses the numerically stable _first-pass pairwise_ algorithm from Ref. [[3]](@ref) to update the mean and variance accumulators. Importantly, the binning analysis is _online_ in the sense that the whole data stream of size `O(N)` need not be stored. Instead, a much smaller data stream of size `O(log N)` needs to be. This makes properly assessing the correlated errors generated from Markov Chain Monte Carlo simulations practical to update _on-the-fly_ [[4]](@ref).

## How to use `OnlineLogBinning`

First, construct an empty `BinningAccumulator` with of `T <: Number` parametric type. Let's take the default `T = Float64` as an example.

```julia
# Initialize a BinningAccumulator{T}
bacc = BinningAccumulator()
```

We currently only support `Float` types, i.e. `T <: AbstractFloat` or `T` is a `Complex{Float#}`. The tested types are listed in [`OLB_tested_numbers`](src/Accumulators/AccumulatorHelpers.jl).

Then, `push!` either a single value or a data stream (sequence of values of `itr` type) to the `BinningAccumulator`. The _online_ analysis will be taken care of automatically.

```julia
# push! a single value into the BinningAccumulator
# Values of incorrect type are converted to the correct type internally
push!(bacc, 1)

# push! a data stream into the BinningAccumulator
push!(bacc, [1, 2, 3, 4, 3, 2, 1])
```

One can then calculate the following statistics from the `BinningAccumulator` at any binning `level = lvl`:

```julia
mean(bacc::BinningAccumulator; level = lvl)           # arithmetic mean
var(bacc::BinningAccumulator; level = lvl)            # sample variance 
std(bacc::BinningAccumulator; level = lvl)            # sample standard deviation 
var_of_mean(bacc::BinningAccumulator; level = lvl)    # variance of the mean 
std_error(bacc::BinningAccumulator; level = lvl)      # standard error of the mean 
```

The binning `level` is optional. By default, the binning `level` is set to `level = 0`. This level, accessed by `bacc[level = 0]`, represents the unbinnned statistics from of the original data stream. The `LevelAccumulator`s from any binning `level` can also be extracted using the overloaded `[]` notation as

```julia
julia> bacc[level = 0]
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 6
    Taccum   = 15.0
    Saccum   = 5.5
    Paccum   = PairAccumulator{Float64}(false, [0.0, 1.0])

    Calculated Level Statistics:
    Current Mean             = 2.5
    Current Variance         = 1.1
    Current Std. Deviation   = 1.0488088481701516
    Current Var. of the Mean = 0.18333333333333335
    Current Std. Error       = 0.42817441928883765

julia> bacc[level = 1]
LevelAccumulator{Float64} with online fields:
    level    = 1
    num_bins = 2
    Taccum   = 5.0
    Saccum   = 2.0
    Paccum   = PairAccumulator{Float64}(false, [0.0, 2.5])

    Calculated Level Statistics:
    Current Mean             = 2.5
    Current Variance         = 2.0
    Current Std. Deviation   = 1.4142135623730951
    Current Var. of the Mean = 1.0
    Current Std. Error       = 1.0
```

## How `OnlineLogBinning` works

The online binning functionality works by combining the method described in [[1]](@ref), where one keeps track of several _accumulators_, with the _first-pass pairwise_ algorithm from [[3]](@ref). The _online_ (i.e. `O(1)`) quantities that are obtained from this process are the `Tvalue`, $T$, and `Svalue`, $S$, from [[3]](@ref), representing the _total accumulator_ and _square accumulator_, respectively, as well as the total number of bins $m$. Together, these online quantities can be combined at any point to yield other (technically) online statistics like the `mean` or `var`iance. These statistics are online in the sense that they are simple function of online accumulators, and so we emphasize their calculation is still amortized with complexity `O(1)`. This is despite that the `mean`, `var`iance, _etc._ are ___not___ updated continuously; only $m$, $T$, and $S$ are.

Using the notation of Ref. [[3]](@ref), the $T$ and $S$ calculated in a data stream comprised of a sequence of $m$ elements,

$$
x_k \in \left\lbrace x_1,x_2,\dots,x_m\right\rbrace
$$

is given by

$$
T_{1,m} = \sum_{k = 1}^m x_k,
$$

$$
S_{1,m} = \sum_{k = 1}^m \left(x_k - \bar{x} \right)^2,
$$

where the mean is given by

$$ \bar{x} = \frac{T_{1,m}}{m}. $$

The variance is then given by

$$ \sigma^2 = \frac{S_{1,m}}{m-1}. $$

These two quantities can be computed _online_ with the _first-pass_ _pairwise_ algorithm given an additional two elements $\left\lbrace x_{m+1}, x_{m+2} \right\rbrace$ using the following expressions:

$$
T_{1,m + 2} = T_{1,m} + T_{m+1,m+2},
$$

$$
S_{1,m + 2} = S_{1, m} + S_{m+1, m+2} + \frac{m}{2(m+2)} \left( \frac{2}{m} T_{1,m} - T_{m+1,m+2} \right)^2,
$$

where

$$
T_{m+1,m+2} = x_{m+1} + x_{m+2},
$$

$$
S_{m+1, m+2} = \frac{1}{2}\left(x_{m+2} - x_{m+1} \right)^2.
$$

We implement this with three nested `Accumulator` `struct`s: the outermost `BinningAccumulator`, the middle-level `LevelAccumulator`, and the innermost `PairAccumulator`. The `BinningAccumulator` stores a `Vector` of `LevelAccumulators`, each of which store their own `PairAccumulator`.

The `PairAccumulator` `struct` is the outward facing element of the `BinningAccumulator` in that it takes in data directly from the data stream. After a _pair_ of values has been imported from the stream, then $\left\lbrace T_{m+1,m+2}, S_{m+1,m+2} \right\rbrace$ are computed and exported to the encapsulating `LevelAccumulator`, where the $\left\lbrace m, T_{1,m}, S_{1,m} \right\rbrace$ accumulator values are stored. Then, the `PairAccumulator` is `reset!`. At the same time, the outermost `BinningAccumulator` passes the $T_{m+1,m+2} / 2$ (_ie_ the pairwise mean) value onto the `PairAccumulator` in the `LevelAccumulator` at the next binning level, where the whole process is repeated again, except the accumulated $T_{1,m+2} / 2$ values comprise the new data stream.

The fact that the data stream is processed in pairs before being passed along to the other binning levels inherently leads to a `bin_depth` given by ${\rm floor}\left[\log_2 (m)\right]$, which is the total number of binning levels in the data stream.

## See Also

1. [`BinningAnalysis.jl`](https://github.com/carstenbauer/BinningAnalysis.jl) for a very similar Julia package which served as an inspiration for this one. Our package does not have as broad of a scope as theirs.
    * One of the authors of [`BinningAnalysis.jl`](https://github.com/carstenbauer/BinningAnalysis.jl) also wrote Ref. [[4]](@ref) which gives a great introduction to the statistical analysis of Monte Carlo data.

1. [`OnlineStats.jl`](https://github.com/joshday/OnlineStats.j) for many more online statistics and routines, most of which are beyond the scope of this package.

## References

<a id="1">[1]</a>
See Section D of M. Wallerberger's _Efficient estimation of autocorrelation spectra_ (2018) at [arXiv:1810.05079](https://arxiv.org/pdf/1810.05079.pdf).

<a id="2">[2]</a>
Ambegaokar, V. and Troyer, M. _Estimating errors reliably in Monte Carlo simulations of the Ehrenfest model_, American Journal of Physics __78__, 150-157 (2010) [doi.org/10.1119/1.3247985](https://doi.org/10.1119/1.3247985)

<a id="3">[3]</a>
Chan, T. F., Golub, G. H., & LeVeque, R. J. (1983). _Algorithms for Computing the Sample Variance: Analysis and Recommendations_. The American Statistician, __37__(3), 242–247. [doi.org/10.2307/2683386](https://doi.org/10.2307/2683386)

<a id="4">[4]</a>
Bauer, C. _Simulating and machine learning quantum criticality in a nearly antiferromagnetic metal_. PhD Dissertation, 2020. Specifically [Section 2.6](http://www.thp.uni-koeln.de/trebst/thesis/PhD_CarstenBauer.pdf).
