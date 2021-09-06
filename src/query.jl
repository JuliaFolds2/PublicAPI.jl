struct API
    mod::Module
    var::Symbol
end

Base.fullname(api::API) = (fullname(api.mod)..., api.var)
Base.Module(api::API) = api.mod
Base.nameof(api::API) = api.var

"""
    PublicAPI.of(provider::Module; [exported], [recursive]) -> apis::Vector

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
- `exported::Bool = true`: Include names marked by `export`.
- `recursive::Bool = true`: Include public APIs from public sub-modules.
"""
function PublicAPI.of(provider::Module; exported::Bool = true, recursive::Bool = true)
    dict = api_by_module()
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
        ns = get(dict, m, nothing)
        if ns !== nothing
            for n in ns
                push!(apis, API(m, n))
                mayberecurse(n)
            end
        end
        if exported
            for n in names(m)
                n in ns && continue
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
    end
    sweep(provider)
    return apis
end

# TODO: Optimize. This is very inefficient.
function api_by_module()
    dict = Dict{Module,Vector{Symbol}}()
    for (m, n) in values(StaticStorages.getbucket(API_BUCKET))
        push!(get!(() -> Symbol[], dict, m), n)
    end
    return dict
end
