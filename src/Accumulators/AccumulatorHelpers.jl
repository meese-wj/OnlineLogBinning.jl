
import StaticArrays: @SVector
"""
    OLB_tested_numbers

Defines the list of tested numerical types for `OnlineLogBinning.jl`.

!!! note
    These types are specifically given as: 
    * `Float16, Float32, Float64` for `Real` numbers.
    * `ComplexF16, ComplexF32, ComplexF64` for `Complex` numbers.
"""
const OLB_tested_numbers = @SVector [ Float16, Float32, Float64,
                                      ComplexF16, ComplexF32, ComplexF64 ]

const OLB_type_union = Union{OLB_tested_numbers...}

_verify_tested_type( type, allowed_types ) = type ∈ allowed_types

function _check_type(type, allowed_types; function_name, print_str = "")
    if !( _verify_tested_type(type, allowed_types) )
        throw(TypeError(function_name, print_str, OLB_type_union, type))
    end
    nothing
end