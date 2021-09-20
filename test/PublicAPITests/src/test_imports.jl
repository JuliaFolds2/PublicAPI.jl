module TestImports

using Test

module Indirection
import PublicAPI
end

module StrictUsing
using ..Indirection
Indirection.PublicAPI.@strict using PublicAPI
end

module StrictImport
using ..Indirection
Indirection.PublicAPI.@strict import PublicAPI
end

function check_common(m::Module)
    @test !isdefined(m, Symbol("@strict"))
    @test !isdefined(m, :of)
    @test isdefined(m.PublicAPI, Symbol("@public"))
    @test isdefined(m.PublicAPI, Symbol("@strict"))
    @test isdefined(m.PublicAPI, :of)
    @test !isdefined(m.PublicAPI, :Internal)
end

function test_strict_using()
    @test isdefined(StrictUsing, Symbol("@public"))
    check_common(StrictUsing)
end

function test_strict_import()
    @test !isdefined(StrictImport, Symbol("@public"))
    check_common(StrictImport)
end

end  # module
