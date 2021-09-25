"""
    API_REGISTRY_NAME::Symbol

The name of a global constant that holds a list `Vector{Symbol}` of public names
in each module.
"""
const API_REGISTRY_NAME = gensym(:API_REGISTRY_NAME)

"""
    @public name₁ name₂ … nameₙ
    @public @macroname

Declare public API names for the current module.

The second form `@public @macroname` is equivalent to `@public var"@macroname"`.

# Extended help

Note that where this macro is invoked is important. Consider:

```julia
module A1
    using PublicAPI: @public
    @public B, C
    module B
        f() = nothing
    end
    module C
        using PublicAPI: @public
        using ..B: f
        @public f
    end
end
```

and

```julia
module A2
    using PublicAPI: @public
    @public B, C
    module B
        using PublicAPI: @public
        f() = nothing
        @public f
    end
    module C
        using ..B: f
    end
end
```

The fully-qualified names `A1.C.f` and `A2.B.f` are public but `A1.B.f` and
`A2.C.f` are private.
"""
macro public(name::Symbol, othernames::Symbol...)
    return public_impl(__module__, [name, othernames...])
end

macro public(macrocall::Expr)
    if macrocall.head !== :macrocall 
        error("Unsupported syntax: $macrocall")
    elseif length(macrocall.args) != 2
        error("Expected single macro name as in `@public @macro`; got: $macrocall")
    end
    return public_impl(__module__, Symbol[macrocall.args[1]])
end

function public_impl(__module__::Module, allnames::Vector{Symbol})
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
