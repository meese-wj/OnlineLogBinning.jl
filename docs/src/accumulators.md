```@meta
DocTestSetup = quote using OnlineLogBinning end
```

# OnlineLogBinning's `Accumulator` `structs`

## `Accumulator` type hierarchy

![BinningAccumulatorDiagram](assets/BinningAccumulatorDiagram.png)

We implement this with three nested `Accumulator` `struct`s: the outermost [`BinningAccumulator`](@ref), the middle-level [`LevelAccumulator`](@ref), and the innermost [`PairAccumulator`](@ref). The [`BinningAccumulator`](@ref) stores a `Vector` of [`LevelAccumulator`](@ref), each of which store their own [`PairAccumulator`](@ref).

## The [`BinningAccumulator`](@ref)

This is the main interface to the binning statistics of a given data stream. The user should basically only mess with this type of object. The binning analysis is performed using it and all important statistical quantities can be found from it.

A [`BinningAccumulator`](@ref) is a wrapper around a `Vector` of [`LevelAccumulator`](@ref)s. For a given data stream of size $N$, there are ${\rm floor}[\log_2(N)]$ _binning levels_. The [`BinningAccumulator`](@ref) has a `length` which is one more than the total number of binning levels, where the bottom-most level, `level = 0`, represents the unbinned data.

## The [`LevelAccumulator`](@ref)

This data structure keeps track of the _online_ [`mean`](@ref) and [`var`](@ref)iance for a given `level`. These accumulated values are only updated though after a _pair_ from the data stream has been read in through the [`LevelAccumulator`](@ref)'s [`PairAccumulator`](@ref).

## The [`PairAccumulator`](@ref)

This is the outward-facing data structure to a given data stream. Once a _pair_ from the data stream has been read, then the [`mean`](@ref) and [`var`](@ref)iance accumulators are updated for a given level, and then the [`mean`](@ref) is propagated to the next binning level, where the process is repeated. This implements the logarithmic binning analysis.

```@meta
DocTestSetup = nothing
```