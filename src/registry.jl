const API_BUCKET = StaticStorages.BucketKey()

"""
    @public(names...)

Declare public API names.
"""
macro public(name::Symbol, othernames::Symbol...)
    allnames = [name]
    append!(allnames, othernames)

    # TODO: Get rid of StaticStorages dependency. Just introduce a global
    # constant `Vector{Symbol}` for each module.

    # Register the public names in a static storage:
    for n in allnames
        StaticStorages.put!(__module__, API_BUCKET, (__module__, n))
    end

    # Check that these names are defined after the module is finalized
    @gensym namespace
    expr = quote
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
