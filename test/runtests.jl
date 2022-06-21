using OnlineLogBinning
using Test
using StaticArrays

# Tested number types for OnlineLogBinning.jl
OLB_tested_numbers = @SVector [ Int8, Int16, Int32, Int64, Int128,
                                UInt8, UInt16, UInt32, UInt64, UInt128,
                                Float16, Float32, Float64,
                                BigInt, BigFloat,
                                Rational,
                                Bool,
                                ComplexF16, ComplexF32, ComplexF64 ]

@testset "OnlineLogBinning.jl" begin
    @testset "Constructors" begin

        @testset "PairAccumulator" begin
            for type ∈ OLB_tested_numbers
                eval(quote
                    @test let
                        pacc = PairAccumulator{$type}()
                        ( pacc.fullpair == true &&
                          pacc.values == @MVector zeros($type, 2) )
                    end
                end)
            end
        end
        
        @testset "LevelAccumulator" begin
            for type ∈ OLB_tested_numbers
                eval(quote
                    @test let
                        lacc = LevelAccumulator{$type}()
                        ( lacc.level == zero(Int) &&
                          lacc.num_bins == zero(Int) &&
                          lacc.Taccum == zero($type) &&
                          lacc.Saccum == zero($type) &&
                          lacc.Paccum.fullpair == true &&
                          lacc.Paccum.values == @MVector zeros($type, 2) )
                    end
                end)
            end
        end

    end
end
