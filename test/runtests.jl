using OnlineLogBinning
using Test

@testset "OnlineLogBinning.jl" begin
    # Write your tests here.
    include("pair_accumulator_tests.jl")
    include("level_accumulator_tests.jl")
    include("binning_accumulator_tests.jl")
end
