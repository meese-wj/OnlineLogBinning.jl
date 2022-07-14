```@meta
DocTestSetup = quote using OnlineLogBinning end
```

# OnlineLogBinning [![Github Link](assets/GitHub-Mark-Light-32px.png)](https://github.com/meese-wj/OnlineLogBinning.jl)

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://meese-wj.github.io/OnlineLogBinning.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://meese-wj.github.io/OnlineLogBinning.jl/dev)
[![Build Status](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/meese-wj/OnlineLogBinning.jl/actions/workflows/CI.yml?query=branch%3Amain)

Julia package to determine effective number of uncorrelated data points in a correlated data stream via an `O(log N)` online binning algorithm.

To use this package, one adds it in any usual _Julian_ way, for example, by simply pressing `]` in the Julia `REPL` to enter `pkg` mode, and then by typing the following

```
pkg> add OnlineLogBinning
```

to download [`OnlineLogBinning.jl`](https://github.com/meese-wj/OnlineLogBinning.jl) from Julia's General Registries. (Remember to press `Backspace` to leave `pkg` mode.)

```@contents
Pages = ["why_binning.md", "accumulators.md", "example.md", "math.md", "related_packages.md", "api.md"]
Depth = 5
```

```@meta
DocTestSetup = nothing
```