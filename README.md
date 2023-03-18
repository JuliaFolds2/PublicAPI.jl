# PublicAPI - this package is still experimental!

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaexperiments.github.io/PublicAPI.jl/dev/)

**NOTE**: This is a proof-of-concept implementation of
[Feature request: `Base.@public` macro for declaring a public name without needing to `export` it · Issue #42117 · JuliaLang/julia](https://github.com/JuliaLang/julia/issues/42117).

PublicAPI.jl provides a simple API for declaring API without `export`ing the
names:

```Julia
using PublicAPI: @public
@public public_api_name
public_api_name() = 1

export exported_and_public_api_name
exported_and_public_api_name() = 2
```

The public API can be queried using `PublicAPI.of(module)`.  For example, the
public API for PublicAPI.jl can be listed as:

```julia
julia> using PublicAPI

julia> apis = PublicAPI.of(PublicAPI);

julia> sort!(fullname.(apis))
3-element Vector{Tuple{Symbol, Symbol}}:
 (:PublicAPI, Symbol("@public"))
 (:PublicAPI, Symbol("@strict"))
 (:PublicAPI, :of)
```

Consumers of the public API can opt-in a stricter semantics of `using` via
`PublicAPI.@strict`

```Julia
import PublicAPI
PublicAPI.@strict using Upstream: api
```

which ensures that `Upstream.api` is either `export`ed or marked as `@public`.
