using Documenter
using PublicAPI

makedocs(
    sitename = "PublicAPI",
    format = Documenter.HTML(),
    modules = [PublicAPI],
    doctest = false,  # tested via test/runtests.jl
    checkdocs = :exports,  # ignore complains about internal docs
    strict = lowercase(get(ENV, "CI", "false")) == "true",
    # See: https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.makedocs
)

deploydocs(
    repo = "github.com/JuliaExperiments/PublicAPI.jl",
    devbranch = "main",  # https://github.com/JuliaDocs/Documenter.jl/issues/1443
    push_preview = true,
    # See: https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.deploydocs
)
