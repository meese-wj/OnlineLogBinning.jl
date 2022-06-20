module OnlineLogBinning

include("Accumulators/BinningAccumulators.jl")
export
# Base overloads
        push!, length, show, eltype,
# Generic-accumulator functionality
        Tvalue, Svalue, _full,
# PairAccumulator-specific functionality
        PairAccumulator, export_TS, increment, 
# LevelAccumulator-specific functionality
        LevelAccumulator, mean, var, var_of_mean, std, std_error, 
        update_Tvalue!, update_Svalue!, update_num_bins!,
# BinningAccumulator-specific functionality
        BinningAccumulator, bin_depth, binning_level

end
