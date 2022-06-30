using OnlineLogBinning
using Documenter
using DocumenterCitations

DocMeta.setdocmeta!(OnlineLogBinning, :DocTestSetup, :(using OnlineLogBinning); recursive=true)

bib = CitationBibliography(joinpath(@__DIR__, "src", "assets", "OLB_references.bib"), sorting = :nty)

makedocs(bib;
    modules=[OnlineLogBinning],
    authors="W. Joe Meese <meese022@umn.edu> and contributors",
    repo="https://github.com/meese-wj/OnlineLogBinning.jl/blob/{commit}{path}#{line}",
    sitename="OnlineLogBinning.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://meese-wj.github.io/OnlineLogBinning.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Why use a Binning Analysis" => "why_binning.md",
        "Example Usage" => "example.md",
        "Accumulator Hierarchy" => "accumulators.md",
        "Mathematical Details" => "math.md",
        "References" => "references.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/meese-wj/OnlineLogBinning.jl",
    devbranch="main",
)
