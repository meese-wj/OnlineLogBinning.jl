module OnlineLogBinning

include("Accumulators/BinningAccumulators.jl")
export
# Base overloads
        push!, length, show, eltype,
# Generic-accumulator functionality
        Tvalue, Svalue, _full, reset!,
        mean, var, var_of_mean, std, std_error,
# PairAccumulator-specific functionality
        PairAccumulator, export_TS, increment, 
# LevelAccumulator-specific functionality
        LevelAccumulator, update_Tvalue!, 
        update_Svalue!, update_num_bins!,
# BinningAccumulator-specific functionality
        BinningAccumulator, bin_depth, binning_level

"""
    mean( lacc::LevelAccumulator )

Online measurement of the [`LevelAccumulator`] mean.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
Statistics.mean( lacc::LevelAccumulator ) = lacc.Taccum / lacc.num_bins
"""
    mean( bacc::BinningAccumulator; [level = 0] )

Online measurement of the [`BinningAccumulator`] mean.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
function Statistics.mean(bacc::BinningAccumulator; level = 0)
    _check_level(bacc, level)
    return mean(bacc.LvlAccums[_binning_index_to_findex(level)])
end

"""
    var( lacc::LevelAccumulator )

Online measurement of the [`LevelAccumulator`] variance.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
Statistics.var( lacc::LevelAccumulator ) = lacc.Saccum / ( lacc.num_bins - one(lacc.num_bins) )
"""
    var( bacc::LevelAccumulator; [level = 0] )

Online measurement of the [`BinningAccumulator`] variance.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
function Statistics.var(bacc::BinningAccumulator; level = 0)
    _check_level(bacc, level)
    return var(bacc.LvlAccums[_binning_index_to_findex(level)])
end

"""
    var_of_mean( lacc::LevelAccumulator ) = var(lacc) / lacc.num_bins

Online measurement of the [`LevelAccumulator`] variance of the mean.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
var_of_mean( lacc::LevelAccumulator ) = var(lacc) / lacc.num_bins
"""
    var_of_mean( bacc::BinningAccumulator; [level = 0] )

Online measurement of the [`BinningAccumulator`] variance of the mean.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
function var_of_mean(bacc::BinningAccumulator; level = 0)
    _check_level(bacc, level)
    return var_of_mean(bacc.LvlAccums[_binning_index_to_findex(level)])
end

"""
    std( lacc::LevelAccumulator ) = sqrt(var(lacc))

Online measurement of the [`LevelAccumulator`] standard deviation.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
Statistics.std( lacc::LevelAccumulator ) = sqrt(var(lacc))
"""
    std( bacc::BinningAccumulator )

Online measurement of the [`BinningAccumulator`] standard deviation.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
function Statistics.std(bacc::BinningAccumulator; level = 0)
    _check_level(bacc, level)
    return std(bacc.LvlAccums[_binning_index_to_findex(level)])
end

"""
    std_error( lacc::LevelAccumulator ) = sqrt(var_of_mean(lacc))

Online measurement of the [`LevelAccumulator`] standard error.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
std_error( lacc::LevelAccumulator ) = sqrt(var_of_mean(lacc))
"""
    std_error( bacc::BinningAccumulator )

Online measurement of the [`BinningAccumulator`] standard error.

# Additional information
* This quantity is considered online despite that it is __not__ regularly updated when data is `push!`ed from the stream.
"""
function std_error(bacc::BinningAccumulator; level = 0)
    _check_level(bacc, level)
    return std_error(bacc.LvlAccums[_binning_index_to_findex(level)])
end

end
