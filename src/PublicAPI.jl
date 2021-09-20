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

let path = joinpath(@__DIR__, "..", "README.md")
    include_dependency(path)
    doc = read(path, String)
    doc = replace(doc, r"^```julia"m => "```jldoctest README")
    @eval PublicAPI $Base.@doc $doc PublicAPI
end

end  # module Internal

@public var"@public"
@public var"@strict"
@public of

end  # baremodule PublicAPI
