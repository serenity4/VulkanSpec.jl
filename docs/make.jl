using VulkanSpecification
using Documenter

DocMeta.setdocmeta!(VulkanSpecification, :DocTestSetup, :(using VulkanSpecification); recursive=true)

makedocs(;
    modules=[VulkanSpecification],
    authors="Cédric BELMANT",
    repo="https://github.com/serenity4/VulkanSpecification.jl/blob/{commit}{path}#{line}",
    sitename="VulkanSpecification.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://serenity4.github.io/VulkanSpecification.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/serenity4/VulkanSpecification.jl",
    devbranch="main",
)
