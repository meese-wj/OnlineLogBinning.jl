using Base
using Statistics

"""
    LevelAccumulator{T <: Number}

Accumulator structure for a given binning level.

# Contents
* `level::Int`
    * Registers the binning level this accumulator is assigned
* `num_bins::Int` 
    * How many elements (i.e. _bins_) have been added to this accumulator
* `Taccum::T`
    * Stands for _Total Accumulator_.
    * This represents the _T_ accumulator for the mean: [`mean`](@ref) `≡ T / num_bins`.
* `Saccum::T`
    * Stands for _Square Accumulator_.
    * This represents the _S_ accumulator for the variance: [`var`](@ref) `≡ S/(num_bins - 1)`.
* `Paccum::PairAccumulator{T}`
    * An outward facing [`PairAccumulator`](@ref) to meet incoming data streams. 
    * This accumulator processes the incoming data and then exports the [`Tvalue`](@ref) and [`Svalue`](@ref) into updates for `Taccum` and `Saccum`, respectively.
"""
mutable struct LevelAccumulator{T <: Number}
    level::Int
    num_bins::Int
    Taccum::T
    Saccum::T
    Paccum::PairAccumulator{T}

    LevelAccumulator{T}() where {T <: Number} = new(zero(Int), zero(Int), zero(T), zero(T), PairAccumulator{T}())
    LevelAccumulator{T}(lvl::Int) where {T <: Number} = new(lvl, zero(Int), zero(T), zero(T), PairAccumulator{T}())
end

_full(lacc::LevelAccumulator) = _full(lacc.Paccum)

function Base.push!(lacc::LevelAccumulator, value::Number)
    push!(lacc.Paccum, value)
    return _full(lacc)
end

"""
    Tvalue(lacc::LevelAccumulator)

Function to calculate the online ``T_{1,m+2}`` summation as:
```math
T_{1,m+2} = T_{1,m} + T_{m+1,m+2},
```
where ``T_{m+1,m+2}`` is the pairwise [`Tvalue`](@ref) for the [`PairAccumulator`](@ref).
"""
Tvalue(lacc::LevelAccumulator, pairT) = lacc.Taccum + pairT

@doc raw"""
    Svalue(lacc::LevelAccumulator)

Function to calculate the online ``S_{1,m+2}`` summation as:
```math
S_{1,m+2} = S_{1,m} + S_{m+1,m+2} + \frac{m}{2(m+2)}\left( \frac{2}{m} T_{1,m} - T_{m+1,m+2} \right)^2.
```
where ``T_{m+1,m+2}`` is the pairwise [`Tvalue`](@ref) for the [`PairAccumulator`](@ref).
"""
function Svalue(lacc::LevelAccumulator, pairS, pairT)
    output = lacc.Saccum + pairS
    output += 0.5 * lacc.num_bins / (lacc.num_bins + 2) * ( 2 / lacc.num_bins * lacc.Taccum - pairT )^2 
    return output
end

"""
    update_Tvalue!(lacc::LevelAccumulator)

Apply the [`Tvalue`](@ref) formula to update `lacc.Taccum` and return the [`PairAccumulator`](@ref) increment.
"""
function update_Tvalue!(lacc::LevelAccumulator)
    Tval = Tvalue(lacc.Paccum)
    lacc.Taccum = Tvalue(lacc, Tval)
    return Tval
end

"""
    update_Svalue!(lacc::LevelAccumulator)

Apply the [`Svalue`](@ref) formula to update `lacc.Saccum` and return the [`PairAccumulator`](@ref) increment.
"""
function update_Svalue!(lacc::LevelAccumulator)
    Sval = Svalue(lacc.Paccum)
    lacc.Saccum = Svalue(lacc, Sval, Tvalue(lacc.Paccum))
    return Sval
end

"""
    update_num_bins!(lacc::LevelAccumulator, [incr = 2])

Increment the number of bins accumulated by `incr`.
"""
update_num_bins!(lacc::LevelAccumulator, incr = 2) = lacc.num_bins += incr

# """
#     set_level!(lacc::LevelAccumulator, lvl)

# Set the bin `level` of the [`LevelAccumulator`](@ref) to be `lvl`.
# Should be used only once after the [`LevelAccumulator`](@ref) has been constructed.
# """
# set_level!(lacc::LevelAccumulator, lvl) = lacc.level = lvl

"""
    mean( acc::LevelAccumulator )

Online measurement of the data stream mean.
"""
Statistics.mean( acc::LevelAccumulator ) = acc.Taccum / acc.num_bins
"""
    var( acc::LevelAccumulator )

Online measurement of the data stream variance.
"""
Statistics.var( acc::LevelAccumulator ) = acc.Saccum / ( acc.num_bins - 1 )