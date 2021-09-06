module TestDoctest

import PublicAPI
using Documenter: doctest
using Test

test() = doctest(PublicAPI; manual = false)

end  # module
