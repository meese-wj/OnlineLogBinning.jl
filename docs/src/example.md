```@meta
DocTestSetup = quote using OnlineLogBinning end
```

# How to use `OnlineLogBinning`

First, construct an empty [`BinningAccumulator`] with of `T <: Number` parametric type. Let's take the default `T = Float64` as an example.

## Initialization

To start, initialize a [`BinningAccumulator`](@ref)`{T}`:
```jldoctest example
julia> bacc = BinningAccumulator()
BinningAccumulator{Float64} with 0 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN
```

!!! note
    We currently only support `Float` types, i.e. `T <: AbstractFloat` or `T` is a `Complex{Float#}`. The tested types are listed in [`OLB_tested_numbers`](@ref).

Then, `push!` either a single value or a data stream (sequence of values of `itr` type) to the `BinningAccumulator`. The _online_ analysis will be taken care of automatically.

## Accumulate data

The easiest way to accumulate data from a data stream is by [`push!`](@ref)ing a single value into the [`BinningAccumulator`](@ref).
```jldoctest example
julia> push!(bacc, 1)
BinningAccumulator{Float64} with 0 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(false, [0.0, 1.0])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

```

!!! note
    Values of incorrect type are converted to the correct type internally.

Additionally, one can [`push!`](@ref) a data stream into the [`BinningAccumulator`](@ref):

```jldoctest example
julia> push!(bacc, [1, 2, 3, 4, 3, 2, 1])
BinningAccumulator{Float64} with 3 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 8
    Taccum   = 17.0
    Saccum   = 8.875
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 2.125
    Current Variance         = 1.2678571428571428
    Current Std. Deviation   = 1.1259916264596033
    Current Var. of the Mean = 0.15848214285714285
    Current Std. Error       = 0.3980981573144277

1th Binning Level:
LevelAccumulator{Float64} with online fields:
    level    = 1
    num_bins = 4
    Taccum   = 8.5
    Saccum   = 3.6875
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 2.125
    Current Variance         = 1.2291666666666667
    Current Std. Deviation   = 1.1086778913041726
    Current Var. of the Mean = 0.3072916666666667
    Current Std. Error       = 0.5543389456520863

2th Binning Level:
LevelAccumulator{Float64} with online fields:
    level    = 2
    num_bins = 2
    Taccum   = 4.25
    Saccum   = 0.28125
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 2.125
    Current Variance         = 0.28125
    Current Std. Deviation   = 0.5303300858899106
    Current Var. of the Mean = 0.140625
    Current Std. Error       = 0.375

3th Binning Level:
LevelAccumulator{Float64} with online fields:
    level    = 3
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(false, [0.0, 2.125])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN
```

!!! note
    The highest binning level will typically yield useless `NaN` statistics, but that just
    reflects the fact that the `num_bins`, `Taccum`, and `Saccum` accumulators are
    only updated once the `level`'s [`PairAccumulator`](@ref) is full.

## Available online statistics

One can then calculate the following statistics from the `BinningAccumulator` at any binning `level = lvl`:

```julia
mean(bacc::BinningAccumulator; level = lvl)           # arithmetic mean
var(bacc::BinningAccumulator; level = lvl)            # sample variance 
std(bacc::BinningAccumulator; level = lvl)            # sample standard deviation 
var_of_mean(bacc::BinningAccumulator; level = lvl)    # variance of the mean 
std_error(bacc::BinningAccumulator; level = lvl)      # standard error of the mean 
```

The binning `level` is optional. By default, the binning `level` is set to `level = 0`. This level, accessed by `bacc[level = 0]`, represents the unbinnned statistics from of the original data stream. The `LevelAccumulator`s from any binning `level` can also be extracted using the overloaded `[]` notation as

```jldoctest example
julia> bacc[level = 0]
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 8
    Taccum   = 17.0
    Saccum   = 8.875
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 2.125
    Current Variance         = 1.2678571428571428
    Current Std. Deviation   = 1.1259916264596033
    Current Var. of the Mean = 0.15848214285714285
    Current Std. Error       = 0.3980981573144277

julia> bacc[level = 1]
LevelAccumulator{Float64} with online fields:
    level    = 1
    num_bins = 4
    Taccum   = 8.5
    Saccum   = 3.6875
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 2.125
    Current Variance         = 1.2291666666666667
    Current Std. Deviation   = 1.1086778913041726
    Current Var. of the Mean = 0.3072916666666667
    Current Std. Error       = 0.5543389456520863
```

## Perform a binning analysis

Once a sufficient amount of data has been binned, one can employ the `BinningAnalysis` routines found in [`BinningAnalysis.jl`](https://github.com/meese-wj/OnlineLogBinning.jl/blob/bbad03e276d6cd27ab3ff173d492c4c551819113/src/BinningAnalysis.jl). To show how this works, we make use of a pre-prepared _random telegraph signal_ generated with the [`TelegraphNoise.jl`](https://github.com/meese-wj/TelegraphNoise.jl) package. The signal is stored as a binary file in [`docs/src/assets`](https://github.com/meese-wj/OnlineLogBinning.jl/tree/bbad03e276d6cd27ab3ff173d492c4c551819113/docs/src/assets).

The simplest one to use is [`fit_RxValues`](@ref) that takes in a single required [`BinningAccumulator`](@ref) as an argument.

```jldoctest BinningAnalysisExample
julia> signal = zeros(Float64, Int(2^18));

julia> read!( joinpath(pwd(), "src", "assets", "telegraph_plateau.bin"), signal);

julia> bacc = BinningAccumulator();

julia> push!(bacc, signal);

julia> result = fit_RxValues(bacc)
Binning Analysis Result:
    Plateau Present:   true
    Fitted Rx Plateau: 14.611315366634937
```

The `Plateau Present` flag indicates whether a [`sigmoid`](@ref) fit to the [`RxValue`](@ref)s is reasonable so as to take its plateau seriously. (See [`_plateau_found`](@ref) for details.) The value of the fitted plateau is also returned. If `Plateau Present == false`, then the plateau is set to be the size of the data stream. This is because the _effective number of uncorrelated_ values in the data stream of size ``M`` is given by ``M_{\rm eff} = M / R_X``.

Other quantities can be extracted from the [`BinningAnalysisResult`](@ref), for example, the [`autocorrelation_time`](@ref) and the [`effective_uncorrelated_values`](@ref) in the data stream.

```jldoctest BinningAnalysisExample
julia> autocorrelation_time(result)
6.8056576833174685

julia> effective_uncorrelated_values(length(signal), result)
17941
```

```@meta
DocTestSetup = nothing
```