using OnlineLogBinning
using Test
using StaticArrays

@testset "OnlineLogBinning.jl" begin
    @testset "Constructors" begin
        # PairAccumulator{Int}
        @test let 
            pacc = PairAccumulator{Int}()
            pacc.fullpair == true && pacc.values == @MVector zeros(Int, 2)            
        end
    end
end
