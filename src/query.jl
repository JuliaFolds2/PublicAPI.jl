"""
    PublicAPI.API

A value representing an API.

An `api::API` supports the following accessor functions:

* `Module(api) :: Module`: module in which the API is defined
* `nameof(api) :: Symbol`: the name of the API in the module
* `fullname(api) :: Tuple{Vararg{Symbol}}`: the components of the
  fully-qualified name; i.e., `(:Package, :SubModule, :function)` for
  `Package.SubModule.function`.
"""
PublicAPI.API

Base.fullname(api::API) = (fullname(api.mod)..., api.var)
Base.Module(api::API) = api.mod
Base.nameof(api::API) = api.var

"""
    PublicAPI.of(provider::Module; [recursive = true]) -> apis::Vector{PublicAPI.API}

List public API from the `provider` module.

See [`PublicAPI.API`](@ref) for methods supported by each element of `apis`.

The `provider` module itself is not included in the `apis`.

# Keyword Arguments
- `recursive::Bool = true`: Include public APIs from public sub-modules.
"""
function PublicAPI.of(provider::Module; recursive::Bool = true)
    apis = Vector{API}()
    function sweep(m::Module)
        function mayberecurse(n::Symbol)
            if recursive
                y = try
                    getfield(m, n)
                catch
                    nothing
                end
                if y isa Module && parentmodule(y) === m && y !== m
                    sweep(y)
                end
            end
        end
        registry = nothing
        if isdefined(m, API_REGISTRY_NAME)
            registry = getfield(m, API_REGISTRY_NAME)
            if registry isa Vector{Symbol}
                for n in registry
                    push!(apis, _API(m, n))
                    mayberecurse(n)
                end
            else
                @error "Malformed API registry found in module `$m`" registry
            end
        end
        for n in names(m)
            if registry !== nothing
                n in registry && continue
            end
            n === nameof(m) && continue  # avoid the module to be listed twice
            if isdefined(m, n)
                push!(apis, _API(m, n))
                mayberecurse(n)
            else
                # Should error?
                @error "Exported but undefined: `$m.$n`"
            end
        end
    end
    sweep(provider)
    return apis
end
