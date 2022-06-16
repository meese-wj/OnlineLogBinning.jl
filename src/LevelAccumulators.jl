
using Statistics

"""
    LevelAccumulator{T <: Number}

Accumulator structure for a given binning level.

# Contents
* `count::Bool`
    * Keeps track of how many elements have been added to `Baccum`
* `level::Int`
    * Registers the binning level this accumulator is assigned
* `nelements::Int` 
    * How many elements have been added to this accumulator
* `Baccum::T`
    * Stands for _Bare Accumulator_. 
    * New data pushed to this accumulator first passes into here.
    * Once `count == true`, then this accumulator is then passed onto `Baccum` in the next binning level. Additionally, it is also sent on to `Taccum` and `Baccum`.
* `Taccum::T`
    * Stands for _Total Accumulator_.
    * This represents the _T_ accumulator for the mean: [`mean`](@ref) `≡ T / nelements`.
* `Saccum::T`
    * Stands for _Square Accumulator_.
    * This represents the _S_ accumulator for the variance: [`var`](@ref) `≡ S/(nelements - 1)`.
"""
mutable struct LevelAccumulator{T <: Number}
    count::Bool
    level::Int
    nelements::Int
    Baccum::T
    Taccum::T
    Saccum::T
end

"""
    mean( acc::LevelAccumulator )

Online measurement of the data stream mean.
"""
Statistics.mean( acc::LevelAccumulator ) = acc.Taccum / acc.nelements
"""
    var( acc::LevelAccumulator )

Online measurement of the data stream variance.
"""
Statistics.var( acc::LevelAccumulator ) = acc.Saccum / ( acc.nelements - 1 )