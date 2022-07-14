```@meta
DocTestSetup = quote using OnlineLogBinning end
```

# Why use a Binning Analysis?

As described in [Wallerberger2019](@cite), [AmbegaokarTroyerEstimatingErrors](@cite), [ChanGolubLeVequeSandT](@cite), [BauerThesis](@cite), and [GubernatisKawashimaWerner](@cite), the presence of correlations in a data stream generated in Markov Chain Monte Carlo simulations renders any measures of error severely underestimated.

## Theoretical background

The naive approach is to calculate the `mean` and the variance of the mean, `var_of_mean`, for a given data stream ``X``. For uncorrelated data, this becomes

```math
\begin{aligned}
\mathtt{mean}(X) &= \frac{1}{M} \sum_{i = 1}^M x_i
\\
\mathtt{var\_of\_mean}(X) &= \frac{1}{M(M-1)} \sum_{i = 1}^M (x_i - \mathtt{mean}(X))^2.
\end{aligned}
```

Fortunately, in the presence of correlations, the `mean` doesn't change. Unfortunately, the `var_of_mean` does. Indeed, one can show that it's given by

```math
\mathtt{var\_of\_mean}(X) = \frac{1 + 2\tau_X}{M(M-1)} \sum_{i = 1}^M (x_i - \mathtt{mean}(X))^2,
```

where the as shown in the Figure within the [`Accumulator` type hierarchy](@ref). Clearly, the uncorrelated `var_of_mean` is just increased by a factor of ``R_X \equiv 1 + 2\tau_X``, where ``\tau_X`` is defined as the _integrated_ [`autocorrelation_time`](@ref) of the data stream. The binning analysis provides a _fast_ as an `O(N)` method for calculating the [`autocorrelation_time`](@ref). It's also _cheap_, only requiring `O(log N)` in RAM.  For those who are unfamiliar with the term, normally one would calculate ``\tau_X`` by

```math
\tau_X = \sum_{i = 1}^M \sum_{i < j} \left[ x_ix_j - \mathtt{mean}(x)^2 \right],
```

which is an  `O(N^2)` summation and can suffer from numerical instabilities.

As one performs pairwise means in each binning level to construct the next highest, and then calculates the `var_of_mean` for each level, one can see that it rises and then eventually saturates around a particular `plateau` value. Normalizing by the original `var_of_mean` calculation _assuming_ the data stream is _uncorrelated_, one can then calculate ``R_X`` in the ``\ell^{\rm th}`` binning level as

```math
R_X(\ell) = \frac{\mathtt{var\_of\_mean}(X^{(\ell)})}{\mathtt{var\_of\_mean}(X^{(0)})} = \frac{ m^{(\ell)} \mathtt{var}(X^{(\ell)}) }{ \mathtt{var}(X^{(0)}) },
```

where `var` is the normal variance and ``m^{(\ell)}`` is the _bin size_, or the number of original data values accumulated into a single data point at the ``\ell^{\rm th}`` level.

## Visualizing a Binning Analysis

The final result of the binning analysis, for sufficiently long data streams, will be to see a [`sigmoid`](@ref)-like curve. We've wrapped up a fitting and plotting workflow into the `plot_binning_analysis` function below to demonstrate how it works. Feel free to skip over to the [Visualization Examples](@ref) if you have your own workflow established.

```@example visualize
using OnlineLogBinning, Plots, LaTeXStrings
pyplot()

# Return the fitted inflection point
sigmoid_inflection(fit) = fit.param[2] / fit.param[3]

# Define a plotting function with Plots.jl
# This function plots the RxValues, the Sigmoid fit,
# the maximum trustworthy level, and the fitted 
# inflection point.
function plot_binning_analysis(bacc)
    # Plot the RxValues irrespective of the trusting cutoff
    all_levels, all_rxvals = levels_RxValues(bacc, false)
    plt = plot( all_levels, all_rxvals; 
                label = "Binning Analysis",
                xlabel = L"Bin Level $\ell$",
                ylabel = L"$R_X(\ell)$",
                markershape = :circle,
                legend = :topleft )

    # Fit only the trustworthy levels
    levels, rxvals = levels_RxValues(bacc)
    fit = fit_RxValues(levels, rxvals)

    # Plot the sigmoid fit
    plot!(plt, all_levels, sigmoid(all_levels, fit.param);
          label = "Sigmoid Fit")

    # Plot the maximum trustworthy level
    vline!(plt, [ max_trustworthy_level(bacc[level = 0].num_bins) ];
           ls = :dash, color = "gray", 
           label = "Maximum Trustworthy Level")

    # Plot the fitted inflection point if it's positive
    if sigmoid_inflection(fit) > zero(fit.param[2])
        vline!(plt, [ sigmoid_inflection(fit) ];
               ls = :dot, color = "red", 
               label = "Sigmoid Inflection Point")
    end
    return plt
end

nothing # hide
```

### Visualization Examples

Now we demonstrate four cases that tend to appear with binning analyses:

1. The binning analysis converges to a plateau for a correlated data stream [``R_X(\ell \rightarrow \infty) > 0``](@ref example_plot_1).
1. The binning analysis reveals that the data stream is truly _uncorrelated_ [``R_X(\ell \rightarrow \infty) = 0``](@ref example_plot_2).
1. The binning analysis has [not converged](@ref example_plot_3) because too few data were taken in the data stream to isolate the uncorrelated data.
1. The binning analyis has not convered because all of the data in the data stream are more-or-less [_equally_ correlated](@ref example_plot_4).

The first two cases are ideal. They represent situations where the data stream has enough data to distinguish correlated blocks from one another. In these first two cases, the [`BinningAnalysisResult`](@ref) will yield `plateau_found == true`.

The second two cases are not so ideal. Either way they show that the correlations in the data stream are so strong that individual uncorrelated blocks can not be robustly created and more sampling is required. Therefore, their [`BinningAnalysisResult`](@ref) yields `plateau_found == false`.

The data shown are pre-simulated signals generated by the [`TelegraphNoise.jl`](https://meese-wj.github.io/TelegraphNoise.jl/dev/) package (`v0.1.0`). _Random telegraph signals_ have an analytically-defined autocorrelation time ``\tau_X`` related to their average dwell time ``T_D`` by ``\tau_X = T_D / 2``. Since the signals are random, they are saved previously, but I'll provide each chosen ``T_D`` for reproducibility purposes.

#### [Example 1: Clear ``R_X`` plateau at a finite value](@id example_plot_1)

This first case shows the textbook ([GubernatisKawashimaWerner](@cite)) example of an ``R_X`` plateau found in a binning analysis. The dwell time for this signal was chosen to be ``T_D = 16``, meaning ``\tau_X = 8``, and the signal generated was ``2^{18} = 262144`` in length.

```@example visualize

# Read in pre-simulated TelegraphNoise.jl data with a plateau
signal = zeros(Float64, Int(2^18))
read!( joinpath("assets", "telegraph_plateau.bin"), signal )
bacc = BinningAccumulator()
push!(bacc, signal)

plot_binning_analysis(bacc)
```

```@meta
DocTestSetup = quote
    using OnlineLogBinning
    signal = zeros(Float64, Int(2^18))
    read!( joinpath("build", "assets", "telegraph_plateau.bin"), signal )
    bacc = BinningAccumulator()
    push!(bacc, signal)
end
```

```jldoctest
result = fit_RxValues(bacc)
result.plateau_found

# output

true
```

Importantly, note that the fitted inflection point is greater than zero, but less than the maximum trustworthy level. The variations in the calculated ``R_X`` values for ``\ell`` greater than the maximum trustworthy level are due to strong fluctuations because of small number statistics.

#### [Example 2: Uncorrelated data ~ ``R_X(\ell \rightarrow \infty) = 0``](@id example_plot_2)

The dwell time for this signal was chosen to be ``T_D = 1/2``, meaning ``\tau_X = 1/4``, and the signal generated was ``2^{14} = 16384`` in length.

```@example visualize

# Read in pre-simulated TelegraphNoise.jl data with a plateau
signal = zeros(Float64, Int(2^14))
read!( joinpath("assets", "telegraph_uncorrelated.bin"), signal )
bacc = BinningAccumulator()
push!(bacc, signal)

plot_binning_analysis(bacc)
```

```@meta
DocTestSetup = quote
    using OnlineLogBinning
    signal = zeros(Float64, Int(2^14))
    read!( joinpath("build", "assets", "telegraph_uncorrelated.bin"), signal )
    bacc = BinningAccumulator()
    push!(bacc, signal)
end
```

```jldoctest
result = fit_RxValues(bacc)
result.plateau_found

# output

true
```

```@meta
DocTestSetup = nothing
```

Notice that the ``R_X`` values decay for increasing ``\ell``. This is because the binning analysis cannot detect any smaller blocks of uncorrelated data since the original data stream is indeed correlated.

#### [Example 3: No plateau due to data insufficiency](@id example_plot_3)

For insufficiently long data streams, we do not expect a plateau, as shown in the following case:

```@example visualize

# Read in pre-simulated TelegraphNoise.jl data without a plateau
signal = zeros(Float64, Int(2^10))
read!( joinpath("assets", "telegraph_no_plateau.bin"), signal )
bacc = BinningAccumulator()
push!(bacc, signal)

plot_binning_analysis(bacc)
```

```@meta
DocTestSetup = quote
    using OnlineLogBinning
    signal = zeros(Float64, Int(2^10))
    read!( joinpath("build", "assets", "telegraph_no_plateau.bin"), signal )
    bacc = BinningAccumulator()
    push!(bacc, signal)
end
```

```jldoctest
result = fit_RxValues(bacc)
result.plateau_found

# output

false
```

```@meta
DocTestSetup = nothing
```

Here, the dwell time was chosen to be ``T_D = 256``, meaning ``\tau_X = 128``, and the signal generated was ``2^{10} = 1024`` in length. Notice, that the binning analysis began to pick up on a set of uncorrelated blocks, but there was not enough simulated data to reveal them before the maximum trustworthy level was reached. In a case like this, one would simply need to run their simulation about _64_ times longer reveal a fitted plateau.

#### [Example 4: No plateau due to totally-correlated data](@id example_plot_4)

In this final example, we demonstrate what happens for a data stream that has "frozen-in" correlations. By this, we mean one where the autocorrelation time ``\tau_X`` far exceeds the data stream size. For this case, ``T_D = 2^{16} = 65536``, so ``\tau_X = 2^{15} = 32768``, while the signal length is only ``2^{12} = 4096``.

```@example visualize

# Read in pre-simulated TelegraphNoise.jl data with a plateau
signal = zeros(Float64, Int(2^12))
read!( joinpath("assets", "telegraph_totally_correlated.bin"), signal )
bacc = BinningAccumulator()
push!(bacc, signal)

plot_binning_analysis(bacc)
```

```@meta
DocTestSetup = quote
    using OnlineLogBinning
    signal = zeros(Float64, Int(2^12))
    read!( joinpath("build", "assets", "telegraph_totally_correlated.bin"), signal )
    bacc = BinningAccumulator()
    push!(bacc, signal)
end
```

```jldoctest
result = fit_RxValues(bacc)
result.plateau_found

# output

false
```

```@meta
DocTestSetup = nothing
```

In this case, eventually the binning analysis returns ``R_X = 0``, since the blocks start comparing literally identical elements. Notice that this case would return a `plateau_found` if it were not for the check if any of the ``R_X`` values were too small. (In principle this case also would result from a data stream with a defined periodicity, despite having correlations, but this is unavoidable.)

!!! tip
    This is the most dangerous case to automate because the [`var`](@ref)iance of such a data stream is naturally very small relative to the [`mean`](@ref). As is the case with all Monte Carlo simulations, or statistical data streams, one should be _very_ wary when the error is a mathematical zero, or vanishingly small compared to the calculated [`mean`](@ref).

```@meta
DocTestSetup = nothing
```