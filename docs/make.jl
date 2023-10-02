using VulkanSpec
using Documenter

DocMeta.setdocmeta!(VulkanSpec, :DocTestSetup, :(using VulkanSpec); recursive=true)

makedocs(;
    modules=[VulkanSpec],
    authors="Cédric BELMANT",
    repo="https://github.com/serenity4/VulkanSpec.jl/blob/{commit}{path}#{line}",
    sitename="VulkanSpec.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://serenity4.github.io/VulkanSpec.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/serenity4/VulkanSpec.jl",
    devbranch="main",
)
