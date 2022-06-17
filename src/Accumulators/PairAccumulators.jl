
using Base
using StaticArrays

"""
    PairAccumulator{T <: Number}

Accumulator that directly faces an incoming data stream. Two values from that stream enter and are processed
into the exported values of [`Tvalue`](@ref) and [`Svalue`](@ref).

# Contents
* `fullpair::Bool`
    * A Boolean to keep track of which element of the pair is being accessed. Additionally, when `fullpair == true` then the contents are exported.
* `values::MVector{2, T}`
    * The individual values taken from the data stream to be processed. Both [`Tvalue`](@ref) and [`Svalue`](@ref) rely on them being accessible.
"""
mutable struct PairAccumulator{T <: Number}
    fullpair::Bool
    values::MVector{2, T}
end

_full(pacc.PairAccumulator) = pacc.fullpair

Base.setindex!(mvec::MVector{2}, b::Bool) = mvec[Int(b) + 1]

@doc raw"""
    Tvalue(pacc::PairAccumulator)

The ``T`` function for a single pair following the accumulation of ``m`` data points follows as 
```math
T_{m+1, m+2} \equiv \sum_{k = m+1}^{m+2} x_k = x_{m+1} + x_{m+2},
```
as expected.
"""
Tvalue(pacc::PairAccumulator) = sum(pacc.values)

@doc raw"""
    Svalue(pacc::PairAccumulator)

The ``S`` function for a single pair following the accumulation of ``m`` data points follows as 
```math
\begin{aligned}
S_{m+1, m+2} &\equiv \sum_{k = m+1}^{m+2} \left( x_k - \frac{1}{2} T_{m+1,m+2} \right)^2
\\
&= \frac{1}{2}\left( x_{m+2} - x_{m+1} \right)^2.
\end{aligned}
```
Thus, ``S_{m+1,m+2}`` does not need to take ``T_{m+1,m+2}`` as an argument.
"""
Svalue(pacc::PairAccumulator) = 0.5 * ( pacc.values[2] - pacc.values[1] )^2
# Svalue(pacc::PairAccumulator) = sum( x -> (x - 0.5 * pacc.Taccum)^2, pacc.values ) old and decrepit...
_export_pair_TS(pacc::PairAccumulator) = @SVector [ pacc.Taccum, pacc.Saccum ]

function Base.empty!(pacc::PairAccumulator{T}) where {T}
    pacc.fullpair = false
    pacc.values .= zero(T)
    return nothing
end

"""
    push!(pacc::PairAccumulator, value::Number) 

Overload `Base.push!` for a [`PairAccumulator`](@ref). One can only 
`push!` a single `value <: Number` at a time into this type of accumulator.
"""
function Base.push!(pacc::PairAccumulator, value::Number)
    pacc.values[pacc.fullpair] = value
    pacc.fullpair = !pacc.fullpair  # TODO: If emptied externally then this is problematic...
    return nothing
end
