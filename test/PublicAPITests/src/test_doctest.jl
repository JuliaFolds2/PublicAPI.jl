module TestDoctest

import PublicAPI
using Documenter: doctest
using Test

function test()
    VERSION ≥ v"1.6" || return
    doctest(PublicAPI; manual = false)
end

end  # module
