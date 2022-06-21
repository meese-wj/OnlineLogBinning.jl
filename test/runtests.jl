using OnlineLogBinning
using Test
using StaticArrays

include("test_helpers.jl")

# test_types = [Float64]

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
                eval( :( @test _PairAccumulator_equality(PairAccumulator{$type}(), 
                                                         PairAccumulator{$type}(true, zeros($type, 2)...)) ) )
            end
        end
        
        @testset "LevelAccumulator" begin
            for type ∈ OLB_tested_numbers, lvl ∈ (0, 1)
                eval(quote
                    @test let
                        lacc1 = LevelAccumulator{$type}()
                        if $lvl != zero(Int)
                            lacc1 = LevelAccumulator{$type}($lvl)
                        end
                        lacc2 = LevelAccumulator{$type}($lvl, zero(Int), zero($type), zero($type), PairAccumulator{$type}())
                        _LevelAccumulator_equality(lacc1, lacc2)
                    end
                end)
            end
        end
        
        @testset "BinningAccumulator" begin
            for type ∈ OLB_tested_numbers
                eval( :( @test _BinningAccumulator_equality( BinningAccumulator{$type}(), 
                                                             BinningAccumulator{$type}( [LevelAccumulator{$type}()] ) ) ) )
            end
        end

    end
end
