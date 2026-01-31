using PreciseTimestamps
using Documenter

DocMeta.setdocmeta!(PreciseTimestamps, :DocTestSetup, :(using PreciseTimestamps); recursive=true)

makedocs(;
    modules=[PreciseTimestamps],
    authors="Galen Lynch <galen@galenlynch.com>",
    sitename="PreciseTimestamps.jl",
    format=Documenter.HTML(;
        canonical="https://galenlynch.github.io/PreciseTimestamps.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/galenlynch/PreciseTimestamps.jl",
    devbranch="main",
)
