
"""
    TRUSTING_CUTOFF = 128

The minimum number of bins required for any
given binning level to be considered statistically
_trustworthy_ so as to minimally suffer from small-number
fluctuations.

!!! note
    This is value is similar to what's given in
    [BauerThesis](@cite) and four times greater than what's 
    in [GubernatisKawashimaWerner](@cite).
"""
const TRUSTING_CUTOFF = 128

@doc raw"""
    max_trustworthy_level(nelements; [trusting_cutoff])

Calculates the highest binning `level` that remains statistically
trustworthy according to the [`TRUSTING_CUTOFF`](@ref), ``t_c``. 

Given a number of elements in a data stream, ``N``, this quantity
is 

```math
\ell_{\rm max} = {\rm floor} \left[ \log_2 \left( \frac{N}{t_c} \right) \right].
```
"""
max_trustworthy_level(nelements; trusting_cutoff = TRUSTING_CUTOFF) = floor(Int, log2(nelements / trusting_cutoff))

@doc raw"""
    trustworthy_level(level; [trustworthy_cutoff = 64])

A binning `level` is said to be a `trustworthy_level` if the number of bins
it contains is greater than or equal to the `trustworthy_cutoff`. 

The number of _bins_ ``N_{\rm bin}`` in any binning `level` is related to 
the number of elements ``N`` and its binning `level` ``\ell \in \{0, 1, \dots \}`` by 

```math
N_{\rm bin} = \frac{N}{2^{\ell}}.
```

This means that, for a given `trustworthy_cutoff` of ``t_c``, then the maximum
number of `trustworthy_level`s present are 

```math
{\rm Total}(\ell) = 1 + {\rm floor} \left[ \log_2 \left( \frac{N}{t_c} \right) \right],
```

where the extra 1 comes from assuming the original data stream has more than ``t_c``
elements in it, making the ``\ell = 0`` `level` a `trustworthy_level`. 

!!! note 
    Basically this just means that the statistics we're showing are not
    susceptible to low-number effects. The ``log_2`` term is the calculated 
    using [`max_trustworthy_level`](@ref).
"""
trustworthy_level(level, nelements; trusting_cutoff = TRUSTING_CUTOFF) = floor(Int, level) <= max_trustworthy_level(nelements; trusting_cutoff = trusting_cutoff)
function trustworthy_level(bacc::BinningAccumulator; trusting_cutoff = TRUSTING_CUTOFF)
    return binning_level.( trustworthy_indices(bacc; trusting_cutoff = trusting_cutoff) )
end

"""
    trustworthy_indices(bacc::BinningAccumulator; [trusting_cutoff])

Return the (Fortran) indices `1, 2, 3, ...` corresponding to [`trustworthy_level`](@ref)s.
"""
function trustworthy_indices(bacc::BinningAccumulator; trusting_cutoff = TRUSTING_CUTOFF)
    ind = zeros(Int, 0)
    for lvl ∈ 0:bin_depth(bacc)
        if trustworthy_level(level, bacc[level = 0].num_bins; trusting_cutoff = trusting_cutoff)
            Base.push!(ind, _binning_index_to_findex(lvl))
        end
    end
    return ind
end

"""
    RxValue(bacc::BinningAccumulator, level)

Compute the ``R_X`` quantity from the binning analysis. This quantity
starts at ``1`` for low binning `level`s, then gradually rises, until the 
bins become statistically uncorrelated at which point ``R_X`` should saturate.
Once saturated, the effective number of uncorrelated elements in a correlated 
data stream of size ``N`` is given in terms of ``R_X`` by ``N / R_X``. 

!!! note
    See [BauerThesis](@cite) and [GubernatisKawashimaWerner](@cite) for details.
"""
RxValue(bacc::BinningAccumulator, level) = var_of_mean(bacc; level = level) / var_of_mean(bacc; level = 0)
"""
    RxValue(bacc::BinningAccumulator, [trustworthy_only = true]; [trusting_cutoff])

Calculate the [`RxValue`](@ref)s from the statistically trustworthy binning `level`s by default,
or from all of them if `trustworthy_only == false`. 
"""
function RxValue(bacc::BinningAccumulator, trustworthy_only = true; trusting_cutoff = TRUSTING_CUTOFF)
    Rxs = RxValue.(bacc, 0:bin_depth(bacc))
    if trustworthy_only
        Rxs = Rxs[ trustworthy_indices(bacc; trusting_cutoff = trusting_cutoff) ]
    end
    return Rxs
end

@doc raw"""
    sigmoid(x, [amp = 1], [θ₁ = 0], [θ₂ = 1])

Calculate a [Sigmoid](https://en.wikipedia.org/wiki/Sigmoid_function?oldformat=true) at a given
argument `x`. The Sigmoid function ``S(x; A, \theta_1, \theta_2)`` is of the form

```math
S(x; A, \theta_1, \theta_2) = \frac{A}{1 + \exp\left( \theta_1 - \theta_2 x \right)}.
```
"""
sigmoid(x, amp = 1, θ₁ = 0, θ₂ = 1) = amp / (1 + exp(θ₁ - θ₂ * x))
"""
    sigmoid(x, pvals) = sigmoid(x, pvals...)

Vectorized [`sigmoid`](@ref) function.
"""
@. sigmoid(x, pvals) = sigmoid(x, pvals...)

"""
    _plateau_found(fit, levels) → Bool

Test whether a plateau has been found from the `fit` using the [`LsqFit.jl`](https://julianlsolvers.github.io/LsqFit.jl/latest/) package.
This includes finding reasonable values for the [`sigmoid`](@ref) parameters.

!!! note
    ### What counts as a plateau?

    A plateau in the [`RxValue`](@ref)s is defined to be present if the following three conditions
    on the [`sigmoid`](@ref) `fit` are all true:
    
    1. The `amp`litude is positive.
    1. The `θ₂` parameter is positive.
    1. The inflection point given by `θ₁ / θ₂ < maximum(levels)`.

    If any of these conditions are violated, then we do not trust that the `[RxValue`](@ref)s have
    actually converged to a single value, meaning that the datastream is not sufficiently large enough
    to separate correlated data from one another.
"""
function _plateau_found( fit, levels )
    params = fit.param
    plateau_found = params[1] > zero(params[1])
    plateau_found *= params[3] > zero(params[3])
    plateau_found *= maximum(levels) > (params[2] / params[3])
    return plateau_found
end

"""
    fit_RxValues(levels, rxvalues, [p0])

Use [`LsqFit.jl`](https://julianlsolvers.github.io/LsqFit.jl/latest/) to fit a [`sigmoid`](@ref)
to a set of [`RxValue`](@ref)s generated by a [`BinningAccumulator`](@ref).

# Additional information
The default arguments passed take on the following values:
* Initial guess for [`sigmoid`](@ref) parameters: `p0 = [1, 0, 1]`.
"""
function fit_RxValues(levels, rxvalues, p0 = [1, 0, 1])
    p0 = convert.(eltype(rxvalues), p0)
    return curve_fit(sigmoid, levels, rxvalues, p0)
end

"""
    fit_RxValues(bacc::BinningAccumulator, [p0])

Use [`LsqFit.jl`](https://julianlsolvers.github.io/LsqFit.jl/latest/) to fit a [`sigmoid`](@ref)
to a [`BinningAccumulator`](@ref). Note, only statistically _trustworthy_ binning `level`s are used.
This function `return`s a [`BinningAnalysis`](@ref) `struct`.

# Additional information
The default arguments passed take on the following values:
* Initial guess for [`sigmoid`](@ref) parameters: `p0 = [1, 0, 1]`.
"""
function fit_RxValues(bacc::BinningAccumulator, p0 = [1, 0, 1]; analysis_type = Float64)
    p0 = convert.(eltype(rxvalues), p0)
    levels = trustworthy_level(bacc)
    rxvalues = RxValue(bacc)
    fit = fit_RxValues(levels, rxvalues, p0)
    return BinningAnalysis{analysis_type}( 
        _plateau_found(fit, trustworthy_level(bacc)),
        ifelse( ana.plateau_found, convert( analysis_type,fit.param[1]), convert(analysis_type, -Inf ) )
     )
end

"""
    BinningAnalysis{T <: AbstractFloat}

Small `struct` to determine if there is a [`_plateau_found`](@ref) from a [`BinningAccumulator`](@ref),
and what its value is.
"""
struct BinningAnalysisResult{T <: AbstractFloat}
    plateau_found::Bool
    RxAmplitude::T
end

@doc raw"""
    autocorrelation_time(RxVal)

Calculation of the autocorrelation time ``\tau_X = \frac{1}{2}\left( R_X - 1 \right)``.
"""
autocorrelation_time(RxVal) = 0.5 * (RxVal - 1)

@doc raw"""
    effective_uncorrelated_values(mvals, RxVal)

Calculation of the effective number of uncorrelated values in a correlated datastream: ``m_{\rm eff} = m / R_X``.
"""
effective_uncorrelated_values(mvals, RxVal) = mvals / RxVal