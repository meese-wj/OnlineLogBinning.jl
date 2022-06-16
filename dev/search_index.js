var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = OnlineLogBinning","category":"page"},{"location":"#OnlineLogBinning","page":"Home","title":"OnlineLogBinning","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for OnlineLogBinning.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [OnlineLogBinning]","category":"page"},{"location":"#OnlineLogBinning.LevelAccumulator","page":"Home","title":"OnlineLogBinning.LevelAccumulator","text":"LevelAccumulator{T <: Number}\n\nAccumulator structure for a given binning level.\n\nContents\n\ncount::Bool\nKeeps track of how many elements have been added to Baccum\nlevel::Int\nRegisters the binning level this accumulator is assigned\nnelements::Int \nHow many elements have been added to this accumulator\nBaccum::T\nStands for Bare Accumulator. \nNew data pushed to this accumulator first passes into here.\nOnce count == true, then this accumulator is then passed onto Baccum in the next binning level. Additionally, it is also sent on to Taccum and Baccum.\nTaccum::T\nStands for Total Accumulator.\nThis represents the T accumulator for the mean: mean ≡ T / nelements.\nSaccum::T\nStands for Square Accumulator.\nThis represents the S accumulator for the variance: var ≡ S/(nelements - 1).\n\n\n\n\n\n","category":"type"},{"location":"#OnlineLogBinning.PairAccumulator","page":"Home","title":"OnlineLogBinning.PairAccumulator","text":"PairAccumulator{T <: Number}\n\n\n\n\n\n","category":"type"},{"location":"#Base.push!-Tuple{PairAccumulator, Number}","page":"Home","title":"Base.push!","text":"push!(pacc::PairAccumulator, value::Number)\n\nOverload Base.push! for a PairAccumulator. One can only  push! a single value <: Number at a time into this type of accumulator.\n\n\n\n\n\n","category":"method"},{"location":"#OnlineLogBinning._pair_S-Tuple{PairAccumulator}","page":"Home","title":"OnlineLogBinning._pair_S","text":"_pair_S(pacc::PairAccumulator)\n\nThe S function for a single pair following the accumulation of m data points follows as \n\nS_m+1 m+2 equiv sum_k = m+1^m+2 left( x_k - frac12 T_m+1m+2 right)^2\n\nClearly, S_m+1m+2 must be called following T_m+1m+2.\n\n\n\n\n\n","category":"method"},{"location":"#OnlineLogBinning._pair_T-Tuple{PairAccumulator}","page":"Home","title":"OnlineLogBinning._pair_T","text":"_pair_T(pacc::PairAccumulator)\n\nThe T function for a single pair following the accumulation of m data points follows as \n\nT_m+1 m+2 equiv sum_k = m+1^m+2 x_k = x_m+1 + x_m+2\n\nas expected.\n\n\n\n\n\n","category":"method"},{"location":"#Statistics.mean-Tuple{LevelAccumulator}","page":"Home","title":"Statistics.mean","text":"mean( acc::LevelAccumulator )\n\nOnline measurement of the data stream mean.\n\n\n\n\n\n","category":"method"},{"location":"#Statistics.var-Tuple{LevelAccumulator}","page":"Home","title":"Statistics.var","text":"var( acc::LevelAccumulator )\n\nOnline measurement of the data stream variance.\n\n\n\n\n\n","category":"method"}]
}
