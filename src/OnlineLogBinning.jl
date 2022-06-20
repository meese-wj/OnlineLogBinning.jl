module OnlineLogBinning

include("Accumulators/BinningAccumulators.jl")
export
# Base overloads
        push!, length, show,
# Generic-accumulator functionality
        Tvalue, Svalue,
# PairAccumulator-specific functionality
        PairAccumulator, export_TS,
# LevelAccumulator-specific functionality
        LevelAccumulator, mean, var, var_of_mean, std, std_error, 
        update_Tvalue!, update_Svalue!, update_num_bins!,
# BinningAccumulator-specific functionality
        BinningAccumulator, bin_depth, binning_level

end
