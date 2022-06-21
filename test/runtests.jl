using OnlineLogBinning
using Test

@testset "OnlineLogBinning.jl" begin
    # Write your tests here.
    include("Accumulator_Tests/pair_accumulator_tests.jl")
    include("Accumulator_Tests/level_accumulator_tests.jl")
    include("Accumulator_Tests/binning_accumulator_tests.jl")
end
