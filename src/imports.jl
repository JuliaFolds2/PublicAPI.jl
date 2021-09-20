# TODO: Support `import` for APIs marked as overloadbale
# TODO: For `using M`, create a shim bare module `B` that only includes exported
# names and then `const M = B; using .M`.
"""
    PublicAPI.@strict using Module: name₁, name₂, …, nameₙ

Enable strict import; i.e., fail on importing non-public API.
"""
macro strict(import_statement::Expr)
    if !(
        import_statement.head === :using &&
        length(import_statement.args) == 1 &&
        all((ex -> Meta.isexpr(ex, :., 1)), import_statement.args[1].args)
    )
        error("Unsupported syntax: ", import_statement)
    end

    @gensym source_module
    M = import_statement.args[1].args[1]
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

    imported_names = map(import_statement.args[1].args[2:end]) do ex
        @assert Meta.isexpr(ex, :., 1)   # what else?
        ex.args[1]::Symbol
    end

    quote
        $import_statement # using M: a, b, c
        $import_source_module # import M as $source_module
        $strict_check($source_module, $(QuoteNode(imported_names)))
        nothing
    end |> esc
end

function strict_check(source_module::Module, imported_names::Vector{Symbol})
    internals = setdiff(imported_names, nameof.(PublicAPI.of(source_module)))
    isempty(internals) && return
    error("Non-public API imported from $source_module: ", join(internals, ", "))
end
