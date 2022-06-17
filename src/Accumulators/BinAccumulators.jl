using Base

include("PairAccumulators.jl")
include("LevelAccumulators.jl")

mutable struct BinAccumulators{T <: Number}
    LvlAccums::Vector{LevelAccumulator{T}}

    BinAccumulators{T}() where {T <: Number} = new([LevelAccumulator{T}()])
end

"""
    push!(bacc::BinAccumulators, value::Number)

Add a single `value` from the data stream into the online binning analysis.
The single value enters at the bin with the lowest 
"""
function Base.push!(bacc::BinAccumulators, value::Number)

end