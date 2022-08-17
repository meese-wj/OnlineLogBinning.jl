
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

"""
    const MINIMUM_RX_64 = eps(Float64)
    const MINIMUM_RX_32 = eps(Float32) 
    const MINIMUM_RX_16 = eps(Float16) 

Minimum allowable variance values based on the least-squares fit type. Any data stream variances smaller
than these are suspiciously small, and one should _not_ trust an automated binning analysis in these instances.
"""
const MINIMUM_VAR_64 = eps(Float64) 
const MINIMUM_VAR_32 = eps(Float32) 
const MINIMUM_VAR_16 = eps(Float16) 

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
        if trustworthy_level(lvl, bacc[level = 0].num_bins; trusting_cutoff = trusting_cutoff)
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
data stream of size ``M`` is given in terms of ``R_X`` by ``M / R_X``. 

!!! note
    See [BauerThesis](@cite) and [GubernatisKawashimaWerner](@cite) for details.
"""
RxValue(bacc::BinningAccumulator, level::Int) = var_of_mean(bacc; level = level) / var_of_mean(bacc; level = 0)
"""
    RxValue(bacc::BinningAccumulator, [trustworthy_only = true]; [trusting_cutoff])

Calculate the [`RxValue`](@ref)s from the statistically trustworthy binning `level`s by default,
or from all of them if `trustworthy_only == false`. 
"""
function RxValue(bacc::BinningAccumulator, trustworthy_only = true; trusting_cutoff = TRUSTING_CUTOFF)
    Rxs = [ RxValue(bacc, lvl) for lvl ∈ 0:bin_depth(bacc) ]
    if trustworthy_only
        Rxs = Rxs[ trustworthy_indices(bacc; trusting_cutoff = trusting_cutoff) ]
    end
    return Rxs
end

"""
    levels_RxValues(bacc::BinningAccumulator, [trustworthy_only = true]; [trusting_cutoff = TRUSTING_CUTOFF])

Return a `Tuple` of identically-sized `Vector`s. The first element of the `Tuple` are the binning `level`s 
and the second are the corresonding [`RxValue`](@ref)s. If `trustworthy_only == true`, then only the 
trustworthy levels and values are returned. If `trustworthy_only == false`, then all levels and values are
returned (except for the last level which is typically not full).

This function is meant to make visualization more convenient and does not offer any different functionality
than what was available before.

!!! compat
    Requires `OnlineLogBinning.jl v0.3.0` or higher.
"""
function levels_RxValues( bacc::BinningAccumulator, trustworthy_only = true; trusting_cutoff = TRUSTING_CUTOFF )
    if trustworthy_only
        return trustworthy_level(bacc; trusting_cutoff = trusting_cutoff), RxValue(bacc, true; trusting_cutoff = trusting_cutoff)
    end
    levels = [lvl for lvl ∈ 0:bin_depth(bacc)]
    return levels[1:(end - 1)], RxValue(bacc, false)[1:(end - 1)]
end

@doc raw"""
    sigmoid(x, [amp = 1], [θ₁ = 0], [θ₂ = 1])

Calculate a [Sigmoid](https://en.wikipedia.org/wiki/Sigmoid_function?oldformat=true) at a given
argument `x`. The Sigmoid function ``S(x; A, \theta_1, \theta_2)`` is of the form

```math
S(x; A, \theta_1, \theta_2) = \frac{A}{1 + \exp\left( \theta_1 - \theta_2 x \right)}.
```
"""
sigmoid(x::Number, amp = 1, θ₁ = 0, θ₂ = 1) = amp / (1 + exp(θ₁ - θ₂ * x))
"""
    sigmoid(x, pvals) = sigmoid(x, pvals...)

Vectorized [`sigmoid`](@ref) function.
"""
sigmoid(x::AbstractVecOrMat, pvals) = sigmoid.(x, pvals...)

@doc raw"""
    sigmoid_jacobian(x, pvals)

Calculate the "Jacobian" of first derivatives for a [`sigmoid`](@ref) to speed the
[`LsqFit`](https://julianlsolvers.github.io/LsqFit.jl/latest/) fitting. The derivatives
are given by 

```math
\begin{aligned}
\frac{\partial S}{\partial A} &= \frac{1}{1 + \exp\left( \theta_1 - \theta_2 x \right)},
\\
&
\\
\frac{\partial S}{\partial \theta_1} &= -\frac{A \, \exp\left( \theta_1 - \theta_2 x \right) }{\left[ 1 + \exp\left( \theta_1 - \theta_2 x \right) \right]^2},
\\
&
\\
\frac{\partial S}{\partial \theta_2} &= \frac{A \, x \, \exp\left( \theta_1 - \theta_2 x \right) }{\left[ 1 + \exp\left( \theta_1 - \theta_2 x \right) \right]^2}.
\end{aligned}
```
"""
function sigmoid_jacobian(x::AbstractVecOrMat, pvals)
    jac = Array{eltype(pvals)}( undef, length(x), length(pvals) )
    # d(sigmoid) / dA
    @.        jac[:, 1] = $one($eltype(jac)) / ( $one($eltype(jac)) + exp( pvals[2] - pvals[3] * x ) )
    # d(sigmoid) / dθ₁
    @. @views jac[:, 2] = -pvals[1] * exp( pvals[2] - pvals[3] * x ) * jac[:, 1]^2
    # d(sigmoid) / dθ₂
    @. @views jac[:, 3] = x * pvals[1] * exp( pvals[2] - pvals[3] * x ) * jac[:, 1]^2
    return jac
end

"""
    _plateau_found(bacc, fit) → Bool

Test whether a plateau has been found from the `fit` using the [`LsqFit.jl`](https://julianlsolvers.github.io/LsqFit.jl/latest/) package.
This includes finding reasonable values for the [`sigmoid`](@ref) parameters.

!!! note
    ### What counts as a plateau?

    A plateau in the [`RxValue`](@ref)s is defined to be present if the following three conditions
    on the [`sigmoid`](@ref) `fit` are all true:
    
    1. None of the computed `level` [`var`](@ref)iances are too small. 
    1. The `amp`litude is positive.
    1. The inflection point given by `θ₁ / θ₂ < max_trustworthy_level(levels)`.

    If any of these conditions are violated, then we do not trust that the [`RxValue`](@ref)s have
    actually converged to a single value, meaning that the datastream is not sufficiently large enough
    to separate correlated data from one another.
"""
function _plateau_found( bacc::BinningAccumulator, fit )
    min_var = MINIMUM_VAR_64
    if eltype(fit.param) === Float16
        min_var = MINIMUM_VAR_16
    elseif eltype(fit.param) === Float32
        min_var = MINIMUM_VAR_32
    end
    level_vars = [ var(bacc; level = lvl) for lvl ∈ 0:(bin_depth(bacc)-1) ]
    plateau_found = all( level_vars .> min_var )
    
    params = fit.param
    plateau_found *= params[1] > zero(params[1])
    plateau_found *= max_trustworthy_level(bacc[level = 0].num_bins) > (params[2] / params[3])
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
    # return curve_fit(sigmoid, levels, rxvalues, p0)
    return curve_fit(sigmoid, sigmoid_jacobian, levels, rxvalues, p0)
end

"""
    fit_RxValues(bacc::BinningAccumulator, [p0])

Use [`LsqFit.jl`](https://julianlsolvers.github.io/LsqFit.jl/latest/) to fit a [`sigmoid`](@ref)
to a [`BinningAccumulator`](@ref). Note, only statistically _trustworthy_ binning `level`s are used.
This function `return`s a [`BinningAnalysisResult`](@ref) `struct`.

# Additional information
The default arguments passed take on the following values:
* Initial guess for [`sigmoid`](@ref) parameters: `p0 = [1, 0, 1]`.
* See [`BinningAnalysisResult`](@ref) for a description of how each `fieldname` is computed.
"""
function fit_RxValues(bacc::BinningAccumulator, p0 = [1, 0, 1]; analysis_type = Float64)
    p0 = convert.(eltype(bacc), p0)
    levels, rxvalues = levels_RxValues(bacc)
    fit = fit_RxValues(levels, rxvalues, p0)
    return BinningAnalysisResult{analysis_type}(bacc, fit)
end

@doc raw"""
    BinningAnalysisResult{T <: AbstractFloat}

Small `struct` to determine if there is a [`_plateau_found`](@ref) from a [`BinningAccumulator`](@ref),
and what its value is.

# Contents
* `plateau_found::Bool`: whether the [`fit_RxValues`](@ref) found a plateau from the binned data.
* `RxAmplitude::T`: the value for the plateau as calculated by [`fit_RxValues`](@ref).
    * If `plateau_found == false`, then `RxAmplitude = length(X)` for a datastream `X`, so as to maximize the error estimation.
* `effective_length::Int`: the effective number of uncorrelated data points in the datastream `X` as calculated by 
```math
m_{\rm eff} = \mathtt{floor} \left( \frac{\mathtt{length}(X)}{R_X} \right).
```
* `binning_mean::T`: the value of the mean as calculated by 
```math
\mathtt{mean}(X) = \frac{ T^{(0)} }{ m^{(0)} }.
```
* `binning_error::T`: the value of the error as calculated by 
```math
\begin{aligned}
\mathtt{error}(X) &= \sqrt{ \frac{ S^{(0)} }{ m_{\rm eff} \left( m^{(0)} - 1 \right) } }
\\
&= \sqrt{ \left[ \mathtt{floor}\left( \frac{m^{(0)}}{R_X} \right) \right]^{-1} \, \frac{ S^{(0)} }{ m^{(0)} - 1 } }.
\end{aligned}
```
"""
struct BinningAnalysisResult{T <: AbstractFloat}
    plateau_found::Bool
    RxAmplitude::T
    effective_length::Int
    binning_mean::T
    binning_error::T
    
    function BinningAnalysisResult{analysis_t}( bacc::BinningAccumulator, fit ) where {analysis_t}
        plateau_found = _plateau_found(bacc, fit)
        # if plateau_found == false, set rxvalue to be the size of the data stream
        rxvalue = ifelse( plateau_found, convert( analysis_t, fit.param[1]), convert(analysis_t, bacc[level = 0].num_bins ) )
        # if rxvalue < 1, then set it equal to 1. Statistics can't get better artificially!
        rxvalue = ifelse( rxvalue < one(rxvalue) || fit.param[3] < zero(fit.param[3]), one(rxvalue), rxvalue)
        meff = effective_uncorrelated_values(bacc[level = 0].num_bins, rxvalue)
        return new{analysis_t}(plateau_found, 
                               rxvalue, 
                               meff, 
                               convert(analysis_t, mean(bacc; level = 0)), 
                               convert(analysis_t, sqrt( var(bacc; level = 0) / meff )))
    end
end

function show(io::IO, result::BinningAnalysisResult)
    println(io, "Binning Analysis Result:")
    println(io, "    Plateau Present:             $(result.plateau_found)")
    println(io, "    Fitted Rx Plateau:           $(result.RxAmplitude)")
    println(io, "    Autocorrelation time τₓ:     $( autocorrelation_time( result ) )")
    println(io, "    Effective Datastream Length: $(result.effective_length)")
    println(io, "    Binning Analysis Mean:       $(result.binning_mean)")
    println(io, "    Binning Analysis Error:      $(result.binning_error)")
end

@doc raw"""
    autocorrelation_time(RxVal)

Calculation of the autocorrelation time ``\tau_X = \frac{1}{2}\left( R_X - 1 \right)``.
"""
autocorrelation_time(RxVal) = 0.5 * (RxVal - 1)
autocorrelation_time(result::BinningAnalysisResult) = autocorrelation_time(result.RxAmplitude)

@doc raw"""
    effective_uncorrelated_values(mvals, RxVal)

Calculation of the effective number of uncorrelated values in a correlated datastream: 
```math
m_{\rm eff} =  \mathtt{floor} \left( \frac{ m^{(0)} }{R_X} \right).
```
"""
effective_uncorrelated_values(mvals, RxVal::Real) = floor(Int, mvals / RxVal)
effective_uncorrelated_values(result::BinningAnalysisResult) = result.effective_length

"""
    measurement(::BinningAnalysisResult)

Convert a [`BinningAnalysisResult`](@ref) into a 
[`Measurements.jl`](https://github.com/JuliaPhysics/Measurements.jl) `measurement`.

!!! compat
    This functionality requires at least `v0.4`.
"""
measurement(result::BinningAnalysisResult) = measurement(result.binning_mean, result.binning_error)