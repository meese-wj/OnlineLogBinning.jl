using Base

include("PairAccumulators.jl")
include("LevelAccumulators.jl")

"""
    BinningAccumulator{T}() where {T <: Number}

Main data structure for the binning analysis. 

# Contents
* `LvlAccums::Vector{LevelAccumulator{T}}`
    * A wrapper around the [`LevelAccumulator`](@ref)s from each binning level
"""
mutable struct BinningAccumulator{T <: Number}
    LvlAccums::Vector{LevelAccumulator{T}}

    # Add an empty LevelAccumulator to the default BinningAccumulator
    BinningAccumulator{T}() where {T <: Number} = new([LevelAccumulator{T}()])
end

"""
    push!(bacc::BinningAccumulator, value::Number)

Add a single `value` from the data stream into the online binning analysis.
The single value enters at the bin at the lowest level. 
"""
function Base.push!(bacc::BinningAccumulator, value::Number)
    value_2_push = convert(eltype(bacc), value)
    level = one(Int)
    push!(bacc.LvlAccums[level], value_2_push)
    
    while _full(bacc.LvlAccums[level])
        # Update Tvalue and Svalue from the original level
        # Then increment the number of bins by 2 (for the pair)
        pairT = update_Tvalue!( bacc.LvlAccums[level] )
        pairS = update_Svalue!( bacc.LvlAccums[level] )
        update_num_bins!( bacc.LvlAccums[level] )

        # Reset the PairAccumulator
        reset!( bacc.LvlAccums[level].Paccum )
        
        # Create a new binning level if level == bin_depth(bacc)
        if level == length(bacc)
            push!(bacc.LvlAccums, LevelAccumulator{eltype(bacc)}(level + 1))
            # set_level!(bacc.LvlAccums[level + 1], level + 1)
        end
        
        # Send Tvalue increment from the fullpair to the next binning level
        level += one(level)
        full = push!(bacc.LvlAccums[level], pairT)
    end
    return bacc
end

"""
    push!(bacc::BinningAccumulator, itr)

`push!` each value of the data stream `itr` through the `BinningAccumulator`.
"""
function Base.push!(bacc::BinningAccumulator, itr)
    @inbounds for value ∈ itr
        push!(bacc, value)
    end
    return nothing
end

"""
    length(bacc::BinningAccumulator)

Return the number of [`LevelAccumulator`](@ref)s there are.
"""
Base.length(bacc::BinningAccumulator) = length(bacc.LvlAccums)
"""
    binning_level(index::Int)

Conversion from `LvlAccums` index to `binning_level`.
"""
binning_level(index::Int) = index - one(index)
"""
    bin_depth(bacc::BinningAccumulator)

Number of binned levels present. [`length`](@ref) of the [`BinningAccumulator`] minus 1.
"""
bin_depth(bacc::BinningAccumulator) = binning_level(length(bacc))

"""
    show([io::IO = stdout], bacc::BinningAccumulator)

Overload the `Base.show` function for _human_-readable displays.
"""
function Base.show(io::IO, bacc::BinningAccumulator)
    println(io, "$(typeof(bacc)) with $(bin_depth(bacc)) binning levels.")
    println(io, "$(binning_level(1))th Binning Level (unbinned data):")
    println(io, "\t$(bacc.LvlAccums[1])")
    for lvl ∈ 2:1:length(bacc.LvlAccums)
        println(io, "$(binning_level(lvl))th Binning Level:")
        println(io, "\t$(bacc.LvlAccums[lvl])")
    end
end

Base.show(bacc::BinningAccumulator) = show(stdout, bacc)

"""
    eltype(bacc::BinningAccumulator{T}) → T

Returns the type parameter for the [`BinningAccumulator`](@ref).
"""
Base.eltype(bacc::BinningAccumulator{T}) where {T} = T