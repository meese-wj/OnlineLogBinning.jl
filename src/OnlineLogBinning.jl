module OnlineLogBinning

include("Accumulators/Accumulators.jl")
export
# Base overloads
        empty!, push!,
# Generic-accumulator functionality
        Tvalue, Svalue,
# PairAccumulator-specific functionality
        PairAccumulator, export_TS,
# LevelAccumulator-specific functionality
        LevelAccumulator, mean, var
        
end
