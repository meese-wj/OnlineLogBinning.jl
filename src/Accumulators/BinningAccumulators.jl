using Base
import Statistics

include("AccumulatorHelpers.jl")
include("PairAccumulators.jl")
include("LevelAccumulators.jl")

"""
    BinningAccumulator{T}() where {T <: Number}

Main data structure for the binning analysis. `T == Float64` by default in the empty constructor.

# Contents
* `LvlAccums::Vector{LevelAccumulator{T}}`
    * A wrapper around the [`LevelAccumulator`](@ref)s from each binning level
"""
mutable struct BinningAccumulator{T <: Number}
    LvlAccums::Vector{LevelAccumulator{T}}

    # Add an empty LevelAccumulator to the default BinningAccumulator
    function BinningAccumulator{T}() where {T} 
        _check_type(T, OLB_tested_numbers; function_name = :BinningAccumulator, print_str = "in the empty constructor", )
        new([LevelAccumulator{T}()])
    end
    # Set a default value for the parametric type `T == Float64`
    BinningAccumulator() = BinningAccumulator{Float64}()
    
    function BinningAccumulator{T}( LvlAccums::Vector{LevelAccumulator{T}} ) where {T}
        _check_type(T, OLB_tested_numbers; function_name = :BinningAccumulator, print_str = "in the (::Vector{LevelAccumulator}) constructor", )
        new( LvlAccums )
    end
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
            push!(bacc.LvlAccums, LevelAccumulator{eltype(bacc)}(binning_level(level + 1)))
            # set_level!(bacc.LvlAccums[level + 1], level + 1)
        end
        
        # Send 0.5 * Tvalue increment from the fullpair (so its mean) to the next binning level
        level += one(level)
        push!(bacc.LvlAccums[level], 0.5 * pairT)
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
    return bacc
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
    eltype(::BinningAccumulator{T}) → T

Returns the type parameter for the [`BinningAccumulator`](@ref).
"""
Base.eltype(::BinningAccumulator{T}) where {T} = T

"""
    reset!(bacc::BinningAccumulator{T})

Reset the [`BinningAccumulator`](@ref) by reconstruction.

# Additional information
While this is not a literal _reset_ per se, with a large enough [`BinningAccumulator`](@ref)
it will be certainly faster just to blow up the old one (in memory) and start over.
"""
reset!(bacc::BinningAccumulator{T}) where {T} = bacc = BinningAccumulator{T}()

_binning_index_to_findex(level) = level + one(Int)

function _check_level(bacc::BinningAccumulator, level)
    if !(level isa Int)
        throw(ArgumentError("level argument: $level must be an integer."))
    end
    if level < zero(Int) || _binning_index_to_findex(level) > length(bacc)
        throw(ArgumentError("level argument $level is out-of-bounds for a BinningAccumulator of length $(length(bacc)).")) 
    end
    return nothing
end