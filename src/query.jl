struct API
    mod::Module
    var::Symbol
end

Base.fullname(api::API) = (fullname(api.mod)..., api.var)
Base.Module(api::API) = api.mod
Base.nameof(api::API) = api.var

"""
    PublicAPI.of(provider::Module; [recursive = true]) -> apis::Vector

List public API from the `provider` module.

Each element `api` of `apis` supports the following accessor functions:

* `Module(api) :: Module`: module in which the API is defined
* `nameof(api) :: Symbol`: the name of the API in the module
* `fullname(api) :: Tuple{Vararg{Symbol}}`: full access pass of the API

In particular,

    fullname(api) === (fullname(Module(api))..., nameof(api))

holds for every `api`.

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
                    push!(apis, API(m, n))
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
                push!(apis, API(m, n))
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
