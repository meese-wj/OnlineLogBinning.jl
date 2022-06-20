module OnlineLogBinning

include("Accumulators/BinningAccumulators.jl")
export
# Base overloads
        push!, length,
# Generic-accumulator functionality
        Tvalue, Svalue,
# PairAccumulator-specific functionality
        PairAccumulator, export_TS,
# LevelAccumulator-specific functionality
        LevelAccumulator, mean, var, update_Tvalue!, update_Svalue!, update_num_bins!,
# BinningAccumulator-specific functionality
        BinningAccumulator, bin_depth

end
