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
    function LevelAccumulator{T}(lvl::Int, num_bins::Int, Taccum::Number, Saccum::Number, Paccum::PairAccumulator{T} ) where {T <: Number}
        return new( lvl, num_bins, convert(T, Taccum), convert(T, Saccum), Paccum )
    end
end

_full(lacc::LevelAccumulator) = _full(lacc.Paccum)

function Base.push!(lacc::LevelAccumulator, value::Number)
    push!(lacc.Paccum, value)
    increment(lacc.Paccum)
    return lacc
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
    if lacc.num_bins > 0
        output += 0.5 * lacc.num_bins / (lacc.num_bins + 2) * ( 2 / lacc.num_bins * lacc.Taccum - pairT )^2 
    end
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

"""
    show([io = stdout], lacc::LevelAccumulator)

Overload `Base.show` for _human_-readable displays.
"""
function Base.show(io::IO, lacc::LevelAccumulator)
    println(io, "$(typeof(lacc)) with online fields:")
    println(io, "\tlevel    = $(lacc.level)")
    println(io, "\tnum_bins = $(lacc.num_bins)")
    println(io, "\tTaccum   = $(lacc.Taccum)")
    println(io, "\tSaccum   = $(lacc.Saccum)")
    println(io, "\tPaccum   = $(lacc.Paccum)")
    println(io, "")
    println(io, "\tOffline Level Statistics:")
    println(io, "\tCurrent Mean             = $(mean(lacc))")
    println(io, "\tCurrent Variance         = $(var(lacc))")
    println(io, "\tCurrent Std. Deviation   = $(std(lacc))")
    println(io, "\tCurrent Var. of the Mean = $(var_of_mean(lacc))")
    println(io, "\tCurrent Std. Error       = $(std_error(lacc))")
end

Base.show(lacc::LevelAccumulator) = Base.show(stdout, lacc)