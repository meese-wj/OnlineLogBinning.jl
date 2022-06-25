```@meta
DocTestSetup = quote using OnlineLogBinning end
```

# OnlineLogBinning

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://meese-wj.github.io/OnlineLogBinning.jl/dev)
[![Build Status](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml?query=branch%3Amain)

Julia package to determine effective number of uncorrelated data points in a correlated data stream via an `O(log N)` online binning algorithm.

## `Accumulator` type hierarchy

We implement this with three nested `Accumulator` `struct`s: the outermost [`BinningAccumulator`](@ref), the middle-level [`LevelAccumulator`](@ref), and the innermost [`PairAccumulator`](@ref). The [`BinningAccumulator`](@ref) stores a `Vector` of [`LevelAccumulator`](@ref), each of which store their own [`PairAccumulator`](@ref).

!!! note 
    For more information, check out [OnlineLogBinning's `Accumulator` `structs`](@ref).

## Similar packages

1. [`BinningAnalysis.jl`](https://github.com/carstenbauer/BinningAnalysis.jl) for a very similar Julia package which served as an inspiration for this one. Our package does not have as broad of a scope as theirs.
    * One of the authors of [`BinningAnalysis.jl`](https://github.com/carstenbauer/BinningAnalysis.jl) also wrote Ref. [BauerThesis](@cite) which gives a great introduction to the statistical analysis of Monte Carlo data.

1. [`OnlineStats.jl`](https://github.com/joshday/OnlineStats.j) for many more online statistics and routines, most of which are beyond the scope of this package.

```@meta
DocTestSetup = nothing
```