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
    repo = "github.com/JuliaLang/PublicAPI.jl",
    push_preview = true,
    # See: https://juliadocs.github.io/Documenter.jl/stable/lib/public/#Documenter.deploydocs
)
