# The Math Behind OnlineLogBinning

The online binning functionality works by combining the method described in Section D of [Wallerberger2019](@cite), as well as in the Dicussion of [AmbegaokarTroyerEstimatingErrors](@cite), where one keeps track of several _accumulators_, with the _first-pass pairwise_ algorithm from [ChanGolubLeVequeSandT](@cite). The _online_ (i.e. `O(1)`) quantities that are obtained from this process are the [`Tvalue`](@ref), ``T``, and [`Svalue`](@ref), ``S``, from [ChanGolubLeVequeSandT](@cite), representing the _total accumulator_ and _square accumulator_, respectively, as well as the total number of bins ``m``. Together, these online quantities can be combined at any point to yield other (technically) online statistics like the `mean` or `var`iance. These statistics are online in the sense that they are simple function of online accumulators, and so we emphasize their calculation is still amortized with complexity `O(1)`. This is despite that the `mean`, `var`iance, _etc._ are __not__ updated continuously; only ``m``, ``T``, and ``S`` are.

Using the notation of Ref. [ChanGolubLeVequeSandT](@cite), the ``T`` and ``S`` calculated in a data stream comprised of a sequence of ``m`` elements,

```math
x_k \in \left\lbrace x_1,x_2,\dots,x_m\right\rbrace
```

is given by

```math
T_{1,m} = \sum_{k = 1}^m x_k,
```

```math
S_{1,m} = \sum_{k = 1}^m \left(x_k - \bar{x} \right)^2,
```

where the mean is given by

```math
\bar{x} = \frac{T_{1,m}}{m}.
```

The variance is then given by

```math
\sigma^2 = \frac{S_{1,m}}{m-1}.
```

These two quantities can be computed _online_ with the _first-pass_ _pairwise_ algorithm given an additional two elements ``\left\lbrace x_{m+1}, x_{m+2} \right\rbrace`` using the following expressions:

```math
T_{1,m + 2} = T_{1,m} + T_{m+1,m+2},
```

```math
S_{1,m + 2} = S_{1, m} + S_{m+1, m+2} + \frac{m}{2(m+2)} \left( \frac{2}{m} T_{1,m} - T_{m+1,m+2} \right)^2,
```

where

```math
T_{m+1,m+2} = x_{m+1} + x_{m+2},
```

```math
S_{m+1, m+2} = \frac{1}{2}\left(x_{m+2} - x_{m+1} \right)^2.
```

We implement this with three nested `Accumulator` `struct`s: the outermost [`BinningAccumulator`](@ref), the middle-level [`LevelAccumulator`](@ref), and the innermost [`PairAccumulator`](@ref). The [`BinningAccumulator`](@ref) stores a `Vector` of `LevelAccumulators`, each of which store their own [`PairAccumulator`](@ref).

The [`PairAccumulator`](@ref) `struct` is the outward facing element of the [`BinningAccumulator`](@ref) in that it takes in data directly from the data stream. After a _pair_ of values has been imported from the stream, then ``\left\lbrace T_{m+1,m+2}, S_{m+1,m+2} \right\rbrace`` are computed and exported to the encapsulating [`LevelAccumulator`](@ref), where the ``\left\lbrace m, T_{1,m}, S_{1,m} \right\rbrace`` accumulator values are stored. Then, the [`PairAccumulator`](@ref) is [`reset!`](@ref). At the same time, the outermost [`BinningAccumulator`](@ref) passes the ``T_{m+1,m+2} / 2`` (_ie_ the pairwise mean) value onto the [`PairAccumulator`](@ref) in the [`LevelAccumulator`](@ref) at the next binning level, where the whole process is repeated again, except the accumulated ``T_{1,m+2} / 2`` values comprise the new data stream.

The fact that the data stream is processed in pairs before being passed along to the other binning levels inherently leads to a [`bin_depth`](@ref) given by ``{\rm floor}\left[\log_2 (m)\right]``, which is the total number of binning levels in the data stream.
