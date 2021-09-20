"""
    API_REGISTRY_NAME::Symbol

The name of a global constant that holds a list `Vector{Symbol}` of public names
in each module.
"""
const API_REGISTRY_NAME = gensym(:API_REGISTRY_NAME)

"""
    @public(names...)

Declare public API names.
"""
macro public(name::Symbol, othernames::Symbol...)
    allnames = [name]
    append!(allnames, othernames)

    @gensym namespace
    expr = quote
        # Allocate the "registry" (just a `Vector{Symbol}`) if it hasn't been
        # defined yet:
        if $Base.:!($Base.@isdefined $API_REGISTRY_NAME)
            const $API_REGISTRY_NAME = $Symbol[]
        end

        # Register the API names:
        $union!($API_REGISTRY_NAME, $(QuoteNode(allnames)))

        # Check that these names are defined after the module is finalized
        module $namespace
        __init__() = $check_public_names($__module__, $(QuoteNode(allnames)))
        end
    end
    @assert expr.head === :block
    return esc(Expr(:toplevel, expr.args...))
end

function check_public_names(__module__::Module, allnames::Vector{Symbol})
    undefined = filter(allnames) do n
        try
            getproperty(__module__, n)
            false
        catch
            true
        end
    end
    if !isempty(undefined)
        are = length(undefined) == 1 ? "is" : "are"
        println(stderr, "ERROR: Following API $are declared but not defined")
        for n in undefined
            println(stderr, "  $__module__.$n")
        end
        error("PublicAPI: $(length(undefined)) undefined public API")
    end
end
