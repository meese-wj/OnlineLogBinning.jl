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
                        Tval = update_SandT!(lacc)
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
                        Tval = update_SandT!(lacc)
                        lacc.Saccum == convert($type, 2)
                    end
                end)
            end
        end

    end

    # Test that only Float types are allowed.
    # See OLB_tested_numbers
    @testset "Type protection in constructors" begin
        
        # Test the empty constructors
        for accum ∈ [:PairAccumulator, :LevelAccumulator, :BinningAccumulator]
            eval(quote
                @testset "$($accum) empty constructor" begin
                    for type ∈ setdiff(all_possible_types, OLB_tested_numbers)
                        eval( :(@test_throws TypeError $($accum){$type}()) )
                    end
                end
            end)
        end

        @testset "PairAccumulator (::Bool, value1, value2) constructor" begin
            type_diff_set = setdiff(all_possible_types, OLB_tested_numbers)
            if VERSION < v"1.7"  # Add this for version 1.3 tests where zero(Irrational) throws a MethodError
                type_diff_set = setdiff(type_diff_set, [Irrational])
            end
            for type ∈ type_diff_set
                eval( :(@test_throws TypeError PairAccumulator{$type}(true, zero($type), zero($type))) )
            end
        end
        
        @testset "LevelAccumulator (::Int) constructor" begin
            for type ∈ setdiff(all_possible_types, OLB_tested_numbers)
                eval( :(@test_throws TypeError LevelAccumulator{$type}(one(Int))) )
            end
        end
        
        @testset "LevelAccumulator (lvl::Int, num_bins::Int, ...) constructor" begin
            for type ∈ setdiff(all_possible_types, OLB_tested_numbers)
                # this tests PairAccumulator more I think, otherwise it throws a MethodError
                eval( :(@test_throws TypeError LevelAccumulator{$type}(one(Int), one(Int), 0.0, 0.0, PairAccumulator{$type}())) )
            end
        end
        
        @testset "BinningAccumulator (::Vector{LevelAccumulator}) constructor" begin
            for type ∈ setdiff(all_possible_types, OLB_tested_numbers)
                # this tests LevelAccumulator more I think, otherwise it throws a MethodError
                eval( :(@test_throws TypeError BinningAccumulator{$type}([ LevelAccumulator{$type}() ])) )
            end
        end
        
        
        
    end

    # Test specific applications of binning
    @testset "Binning specific data streams" begin
        
        @testset "Sample up down data stream" begin 
            test_data = [1, -1, -1, -1, 1, -1, -1, 1, 1, 1, -1, 1, -1, 1, 1, -1]
            bacc = BinningAccumulator()
            push!(bacc, test_data)

            @testset "level = 0" begin
                _test_level_statistics(bacc; level = 0, 
                                       known_mean = zero(eltype(bacc)),
                                       known_var = 16/15,
                                       known_var_of_mean = 1/15,
                                       known_std = 1.0327955589886444,
                                       known_std_err = 0.2581988897471611 )
                
                @test _LevelAccumulator_equality(bacc.LvlAccums[begin],
                                                 LevelAccumulator{eltype(bacc)}(0, 16, 0., 16., PairAccumulator{eltype(bacc)}(true, 0., 0.) ) )
            end
            
            @testset "level = 0" begin
                _test_level_statistics(bacc; level = 0, 
                                       known_mean = zero(eltype(bacc)),
                                       known_var = 16/15,
                                       known_var_of_mean = 1/15,
                                       known_std = 1.0327955589886444,
                                       known_std_err = 0.2581988897471611 )
                
                @test _LevelAccumulator_equality(bacc.LvlAccums[begin],
                                                 LevelAccumulator{eltype(bacc)}(0, 16, 0., 16., PairAccumulator{eltype(bacc)}(true, 0., 0.) ) )
            end
        end
        
    end

end
