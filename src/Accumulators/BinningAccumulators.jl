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

# Example 
```jldoctest
julia> # Create a BinningAccumulator with the default type T == Float64

julia> bacc = BinningAccumulator()  
BinningAccumulator{Float64} with 0 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

julia> # Add a data stream using the push! function

julia> # (The data stream does not have to have a length == power of 2.)

julia> push!(bacc, [1, 2, 3, 4])
BinningAccumulator{Float64} with 2 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 4
    Taccum   = 10.0
    Saccum   = 5.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 2.5
    Current Variance         = 1.6666666666666667
    Current Std. Deviation   = 1.2909944487358056
    Current Var. of the Mean = 0.4166666666666667
    Current Std. Error       = 0.6454972243679028

1th Binning Level:
LevelAccumulator{Float64} with online fields:
    level    = 1
    num_bins = 2
    Taccum   = 5.0
    Saccum   = 2.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 2.5
    Current Variance         = 2.0
    Current Std. Deviation   = 1.4142135623730951
    Current Var. of the Mean = 1.0
    Current Std. Error       = 1.0

2th Binning Level:
LevelAccumulator{Float64} with online fields:
    level    = 2
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(false, [0.0, 2.5])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

```
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
    _binning_index_to_findex(level)

Convert the `binning_index ∈ {0, 1, ... }` to a (Fortran) `findex ∈ {1, 2, ... }`.
"""
_binning_index_to_findex(level) = level + one(Int)

"""
    getindex(bacc::BinningAccumulator; level)

Overload the `[]` notation by accessing the [`BinningAccumulator`](@ref)'s `LvlAccums`
at a specific binning `level` keyword.

# Example
```jldoctest
julia> bacc = BinningAccumulator();

julia> bacc[level = 0]
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

```
"""
Base.getindex(bacc::BinningAccumulator; level) = bacc.LvlAccums[_binning_index_to_findex(level)]

"""
    push!(bacc::BinningAccumulator, value::Number)

Add a single `value` from the data stream into the online binning analysis.
The single value enters at the bin at the lowest level. 

# Example

```jldoctest
julia> bacc = BinningAccumulator()
BinningAccumulator{Float64} with 0 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

julia> push!(bacc, 42)
BinningAccumulator{Float64} with 0 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(false, [0.0, 42.0])        

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

```
!!! note
    Notice that the `Taccum` and `Saccum` remain zero while `num_bins == 0`. 
    These are only accumulated for each input pair. Or once `Paccum.fullpair == true`.
"""
function Base.push!(bacc::BinningAccumulator, value::Number)
    value_2_push = convert(eltype(bacc), value)
    level = one(Int)
    push!(bacc.LvlAccums[level], value_2_push)
    
    while _full(bacc.LvlAccums[level])
        # Update Tvalue and Svalue from the original level
        # Then increment the number of bins by 2 (for the pair)
        pairT = update_SandT!( bacc.LvlAccums[level] )
        update_num_bins!( bacc.LvlAccums[level] )

        # Reset the PairAccumulator
        reset!( bacc.LvlAccums[level].Paccum )
        
        # Create a new binning level if level == bin_depth(bacc)
        if level == length(bacc)
            push!(bacc.LvlAccums, LevelAccumulator{eltype(bacc)}(binning_level(level + 1)))
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

# Example 
```jldoctest
julia> bacc = BinningAccumulator()
BinningAccumulator{Float64} with 0 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

julia> push!(bacc, [42, -26])
BinningAccumulator{Float64} with 1 binning levels.
0th Binning Level (unbinned data):
LevelAccumulator{Float64} with online fields:
    level    = 0
    num_bins = 2
    Taccum   = 16.0
    Saccum   = 2312.0
    Paccum   = PairAccumulator{Float64}(true, [0.0, 0.0])

    Calculated Level Statistics:
    Current Mean             = 8.0
    Current Variance         = 2312.0
    Current Std. Deviation   = 48.08326112068523
    Current Var. of the Mean = 1156.0
    Current Std. Error       = 34.0

1th Binning Level:
LevelAccumulator{Float64} with online fields:
    level    = 1
    num_bins = 0
    Taccum   = 0.0
    Saccum   = 0.0
    Paccum   = PairAccumulator{Float64}(false, [0.0, 8.0])

    Calculated Level Statistics:
    Current Mean             = NaN
    Current Variance         = -0.0
    Current Std. Deviation   = -0.0
    Current Var. of the Mean = NaN
    Current Std. Error       = NaN

```
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

# Example 
```jldoctest
julia> bacc = BinningAccumulator();

julia> push!(bacc, [1, 2, 3, 4, 3, 2, 1]); # Data stream with 7 elements

julia> length(bacc) # Only 2 binning levels (1 for unbinned data)
3
```
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

# Example 
```jldoctest
julia> bacc = BinningAccumulator();

julia> push!(bacc, [1, 2, 3, 4, 3, 2, 1]); # Data stream with 7 elements

julia> bin_depth(bacc) # Only 2 binning levels (1 for unbinned data)
2
```
"""
bin_depth(bacc::BinningAccumulator) = binning_level(length(bacc))

"""
    show([io::IO = stdout], bacc::BinningAccumulator)

Overload the `Base.show` function for _human_-readable displays.
"""
function Base.show(io::IO, bacc::BinningAccumulator)
    println(io, "$(typeof(bacc)) with $(bin_depth(bacc)) binning levels.")
    println(io, "$(binning_level(1))th Binning Level (unbinned data):")
    println(io, "$(bacc.LvlAccums[1])")
    for lvl ∈ 2:1:length(bacc.LvlAccums)
        println(io, "$(binning_level(lvl))th Binning Level:")
        println(io, "$(bacc.LvlAccums[lvl])")
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

function _check_level(bacc::BinningAccumulator, level)
    if !(level isa Int)
        throw(ArgumentError("level argument: $level must be an integer."))
    end
    if level < zero(Int) || _binning_index_to_findex(level) > length(bacc)
        throw(ArgumentError("level argument $level is out-of-bounds for a BinningAccumulator of length $(length(bacc)).")) 
    end
    return nothing
end