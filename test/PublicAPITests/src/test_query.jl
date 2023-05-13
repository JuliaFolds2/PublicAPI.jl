module TestQuery

import PublicAPI
using Test
import ..PublicAPITests

function test_of()
    apis = PublicAPI.of(PublicAPI)
    @test sort!(nameof.(apis)) == [Symbol("@public"), Symbol("@strict"), :API, :of]
    @test Module.(apis) == fill(PublicAPI, 4)
end

function test_recursive()
    apis = PublicAPI.of(PublicAPITests)
    @test sort!(nameof.(apis)) == [:InplaceSamples, :ONE, :TWO]
end

end  # module
