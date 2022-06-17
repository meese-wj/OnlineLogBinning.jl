using Base

include("PairAccumulators.jl")
include("LevelAccumulators.jl")

mutable struct BinningAccumulator{T <: Number}
    LvlAccums::Vector{LevelAccumulator{T}}

    # Add an empty LevelAccumulator to the default BinningAccumulator
    BinningAccumulator{T}() where {T <: Number} = new([LevelAccumulator{T}()])
end

"""
    push!(bacc::BinAccumulators, value::Number)

Add a single `value` from the data stream into the online binning analysis.
The single value enters at the bin with the lowest 
"""
function Base.push!(bacc::BinningAccumulators, value::Number)

end