module PublicAPITests

using PublicAPI: @public

@public ONE InplaceSamples
const ONE = 1

module InplaceSamples
using PublicAPI: @public
@public TWO
const TWO = 1
end  # module InplaceSamples

include("utils.jl")
include("test_samples.jl")
include("test_query.jl")
include("test_imports.jl")
include("test_doctest.jl")

end  # module PublicAPITests
