# TODO: Support `import` for APIs marked as overloadbale
"""
    PublicAPI.@strict using Module: name₁, name₂, …, nameₙ
    PublicAPI.@strict using Module
    PublicAPI.@strict import Module

Enable strict import; i.e., fail on using non-public API.

The simple forms `using Module` and `import Module` create a dummy object named
`Module` that acts like the original `Module` but forbids access to the internal
names.

# Extended help

Limitation: Currently, `PublicAPI.@strict` with the simple forms `using Module`
and `import Module` creates a dummy local module and a global constant named
`Module` is bind to it.  Thus, unlike `using Module`, the expression
`PublicAPI.@strict using Module` cannot be evaluated more than once inside a
module.  This is an implementation detail that may be fixed in the future if we
find a better implementation.
"""
macro strict(import_statement::Expr)
    @gensym source_module
    if is_explicit_using(import_statement)  # using M: a.b.c
        import_expr = import_statement
        M = import_statement.args[1].args[1]

        imported_names = map(import_statement.args[1].args[2:end]) do ex
            @assert Meta.isexpr(ex, :., 1)   # what else?
            ex.args[1]::Symbol
        end
    elseif is_simple_using(import_statement) || is_simple_import(import_statement)
        fullpath = import_statement.args[1].args
        shim = gensym("PublicAPI_wrapper_" * join(fullpath, "."))
        lastname = fullpath[end]::Symbol
        import_expr = quote
            baremodule $shim
            $(Expr(:import, import_statement.args[1]))
            for api in $PublicAPI.of($lastname)
                name = $nameof(api)
                $Base.@eval $shim const $(Expr(:$, :name)) =
                    $lastname.$(Expr(:$, :name))
            end
            for name in $names($lastname)
                $Base.@eval $shim export $(Expr(:$, :name))
            end
            end
            const $lastname = $shim
            if $(is_simple_using(import_statement))
                using .$shim
            end
        end
        @assert import_expr.head === :block
        import_expr = Expr(:toplevel, import_expr.args...)
        M = import_statement.args[1]
        imported_names = Symbol[]  # no need to check
    else
        error("Unsupported syntax: ", import_statement)
    end

    if VERSION ≥ v"1.6"
        import_source_module = Expr(:import, Expr(:as, M, source_module))
    else
        @gensym scratch
        import_source_module = quote
            module $scratch
            $(Expr(:import, M))
            const $source_module = $(M.args[end])
            end
            using .$scratch: $source_module
        end
        @assert import_source_module.head === :block
        import_source_module = Expr(:toplevel, import_source_module.args...)
    end

    quote
        $import_expr # e.g., using M: a, b, c
        $import_source_module # import M as $source_module
        $strict_check($source_module, $(QuoteNode(imported_names)))
        nothing
    end |> esc
end

"""
    is_simple_using(ex::Expr) :: Bool

Check if `ex` is of the form `using Module`.
"""
is_simple_using(ex::Expr, head = :using) =
    ex.head === head &&
    length(ex.args) == 1 &&
    Meta.isexpr(ex.args[1], :., 1) &&
    all(x -> x isa Symbol, ex.args[1].args)

"""
    is_simple_import(ex::Expr) :: Bool

Check if `ex` is of the form `import Module`.
"""
is_simple_import(ex::Expr) = is_simple_using(ex, :import)

"""
    is_explicit_using(ex::Expr) :: Bool

Check if `ex` is of the form `using Module: name₁, name₂, …, nameₙ`.
"""
is_explicit_using(ex::Expr) =
    ex.head === :using &&
    length(ex.args) == 1 &&
    Meta.isexpr(ex.args[1], :(:)) &&
    all((x -> Meta.isexpr(x, :., 1)), ex.args[1].args)

function strict_check(source_module::Module, imported_names::Vector{Symbol})
    internals = setdiff(imported_names, nameof.(PublicAPI.of(source_module)))
    isempty(internals) && return
    error("Non-public API imported from $source_module: ", join(internals, ", "))
end
