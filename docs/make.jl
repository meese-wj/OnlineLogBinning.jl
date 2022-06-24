using OnlineLogBinning
using Documenter

DocMeta.setdocmeta!(OnlineLogBinning, :DocTestSetup, :(using OnlineLogBinning); recursive=true)

makedocs(;
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
        "Home" => "home.md",
        "API" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/meese-wj/OnlineLogBinning.jl",
    devbranch="main",
)
