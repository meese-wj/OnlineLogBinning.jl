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

The final result of the binning analysis, for sufficiently long data streams, will be to see a [`sigmoid`](@ref)-like curve:

```@eval
using OnlineLogBinning, Plots, LaTeXStrings
pyplot()

signal = zeros(Float64, Int(2^18))
read!( joinpath("assets", "telegraph_plateau.bin"), signal)
bacc = BinningAccumulator()
push!(bacc, signal)

all_levels = [lvl for lvl in 0:(bin_depth(bacc) - 1)]
plt = plot( all_levels, RxValue(bacc, false)[1:(end - 1)];
            label = "Binning Analysis", 
            xlabel = L"Bin Level $\ell$",
            ylabel = L"$R_X(\ell)$",
            markershape = :circle,
            legend = :topleft )

levels = trustworthy_level(bacc)
rxvalues = RxValue(bacc)
fit = fit_RxValues( levels, rxvalues )

plot!( plt, all_levels, sigmoid(all_levels, fit.param);
       label = "Sigmoid Fit" )

vline!( plt, [max_trustworthy_level(bacc[level = 0].num_bins)];
        ls = :dash, color = "gray", label = "Maximum Trustworthy Level")

savefig(joinpath("assets", "plateau_plot.png"))

GC.gc()
```

![PlateauPlot](assets/plateau_plot.png)

For insufficiently long data streams, we do not expect a plateau, as shown in the following case:

```@eval
using OnlineLogBinning, Plots, LaTeXStrings
pyplot()

signal = zeros(Float64, Int(2^10))
read!( joinpath("assets", "telegraph_no_plateau.bin"), signal)
bacc = BinningAccumulator()
push!(bacc, signal)

all_levels = [lvl for lvl in 0:(bin_depth(bacc) - 1)]
plt = plot( all_levels, RxValue(bacc, false)[1:(end - 1)];
            label = "Binning Analysis", 
            xlabel = L"Bin Level $\ell$",
            ylabel = L"$R_X(\ell)$",
            markershape = :circle,
            legend = :topleft )

levels = trustworthy_level(bacc)
rxvalues = RxValue(bacc)
fit = fit_RxValues( levels, rxvalues )

plot!( plt, all_levels, sigmoid(all_levels, fit.param);
       label = "Sigmoid Fit" )

vline!( plt, [max_trustworthy_level(bacc[level = 0].num_bins)];
        ls = :dash, color = "gray", label = "Maximum Trustworthy Level")

savefig(joinpath("assets", "no_plateau_plot.png"))

GC.gc()
```

![NoPlateauPlot](assets/no_plateau_plot.png)

Indeed, we have actually chosen the [`sigmoid`](@ref), as its inflection point is easily calculable. If the _Maximum Trustworthy Level_ is less than the fitted inflection point, then our binning analysis says no plateau was found, and by default it returns the maximal value of ``R_X``.

```@meta
DocTestSetup = nothing
```