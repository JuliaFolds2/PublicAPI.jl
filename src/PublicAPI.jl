baremodule PublicAPI

export @public

macro public end
macro strict end

function of end

module Internal

using ..PublicAPI: PublicAPI
import ..PublicAPI: @public, @strict

include("registry.jl")
include("query.jl")
include("imports.jl")

# Import README as a docstring for testing it via doctest.
# Not calling `@eval` here to avoid "eval from module PublicAPI to Internal".
function define_docstring()
    path = joinpath(@__DIR__, "..", "README.md")
    include_dependency(path)
    doc = read(path, String)
    doc = replace(doc, r"^```julia"m => "```jldoctest README")
    @eval PublicAPI $Base.@doc $doc PublicAPI
end

end  # module Internal

Internal.define_docstring()

@public @public
@public @strict
@public of

end  # baremodule PublicAPI
