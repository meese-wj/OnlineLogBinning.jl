using OnlineLogBinning
import OnlineLogBinning: OLB_tested_numbers
using Test
using StaticArrays

include("test_helpers.jl")

# test_types = [Float64]

# Tested number types for OnlineLogBinning.jl
const all_possible_types = @SVector [ Int8, Int16, Int32, Int64, Int128,
                                      UInt8, UInt16, UInt32, UInt64, UInt128,
                                      Float16, Float32, Float64,
                                      BigInt, BigFloat,
                                      Rational, Irrational,
                                      Bool,
                                      ComplexF16, ComplexF32, ComplexF64 ]


@testset "OnlineLogBinning.jl" begin
    
    # These tests eliminated Bools and Irrationals
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

    # These tests eliminated BigInts, BigFloats, Rationals, Ints, and UInts
    @testset "Tvalue and Svalue" begin
        
        @testset "PairAccumulator Tvalue" begin
            for type ∈ OLB_tested_numbers
                eval(quote
                    @test let
                        values = convert.($type, [2, 3])
                        Tval = Tvalue(PairAccumulator{$type}(true, values...))
                        Tval == convert($type, 5)
                    end
                end)
            end
        end
        
        @testset "PairAccumulator Svalue" begin
            for type ∈ OLB_tested_numbers
                eval(quote
                    @test let
                        values = convert.($type, [2, 4])
                        Sval = Svalue(PairAccumulator{$type}(true, values...))
                        Sval == convert($type, 2)
                    end
                end)
            end
        end

        @testset "LevelAccumulator Tvalue" begin
            for type ∈ OLB_tested_numbers
                eval(quote
                    @test let
                        values = convert.($type, [2, 3])
                        lacc = LevelAccumulator{$type}()
                        push!(lacc, values[1])
                        push!(lacc, values[2])
                        Tval = update_Tvalue!(lacc)
                        Tval == convert($type, 5)
                    end
                end)
            end
        end
        
        @testset "LevelAccumulator Svalue" begin
            for type ∈ OLB_tested_numbers
                eval(quote
                    @test let
                        values = convert.($type, [2, 4])
                        lacc = LevelAccumulator{$type}()
                        push!(lacc, values[1])
                        push!(lacc, values[2])
                        Tval = update_Svalue!(lacc)
                        Tval == convert($type, 2)
                    end
                end)
            end
        end

    end

    # Test that only Float types are allowed.
    # See OLB_tested_numbers
    @testset "Type protection in constructors" begin
        
        @testset "BinningAccumulator empty constructor" begin
            for type ∈ setdiff(all_possible_types, OLB_tested_numbers)
                eval( :(@test_throws TypeError BinningAccumulator{$type}()) )
            end
        end
        
    end
end
