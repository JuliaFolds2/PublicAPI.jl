module TestImports

using Test

module Indirection
import PublicAPI
end

module StrictImport
using ..Indirection
Indirection.PublicAPI.@strict import PublicAPI
end

function test_strict_import()
    @test !isdefined(StrictImport, Symbol("@public"))
    @test !isdefined(StrictImport, Symbol("@strict"))
    @test !isdefined(StrictImport, :of)
    @test isdefined(StrictImport.PublicAPI, Symbol("@public"))
    @test isdefined(StrictImport.PublicAPI, Symbol("@strict"))
    @test isdefined(StrictImport.PublicAPI, :of)
    @test !isdefined(StrictImport.PublicAPI, :Internal)
end

end  # module
