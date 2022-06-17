using Base
using Statistics

"""
    LevelAccumulator{T <: Number}

Accumulator structure for a given binning level.

# Contents
* `level::Int`
    * Registers the binning level this accumulator is assigned
* `nelements::Int` 
    * How many elements have been added to this accumulator
* `Taccum::T`
    * Stands for _Total Accumulator_.
    * This represents the _T_ accumulator for the mean: [`mean`](@ref) `≡ T / nelements`.
* `Saccum::T`
    * Stands for _Square Accumulator_.
    * This represents the _S_ accumulator for the variance: [`var`](@ref) `≡ S/(nelements - 1)`.
* `Paccum::PairAccumulator{T}`
    * An outward facing [`PairAccumulator`](@ref) to meet incoming data streams. 
    * This accumulator processes the incoming data and then exports the [`Tvalue`](@ref) and [`Svalue`](@ref) into updates for `Taccum` and `Saccum`, respectively.
"""
mutable struct LevelAccumulator{T <: Number}
    level::Int
    nelements::Int
    Taccum::T
    Saccum::T
    Paccum::PairAccumulator{T}
end

_full(lacc::LevelAccumulator) = _full(lacc.Paccum)

function Base.push!(lacc::LevelAccumulator, value::Number)
    push!(lacc.Paccum, value)
    return _full(lacc)
end

function Base.accumulate!(lacc::LevelAccumulator)
    lacc.Taccum += Tvalue(lacc)
    lacc.Saccum += Svalue(lacc)
    return nothing
end

"""
    mean( acc::LevelAccumulator )

Online measurement of the data stream mean.
"""
Statistics.mean( acc::LevelAccumulator ) = acc.Taccum / acc.nelements
"""
    var( acc::LevelAccumulator )

Online measurement of the data stream variance.
"""
Statistics.var( acc::LevelAccumulator ) = acc.Saccum / ( acc.nelements - 1 )