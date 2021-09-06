module TestSamples

using ..Utils
using Test

const SAMPLES = joinpath(@__DIR__, "../../samples")

function test_undefined_positive()
    proc = Utils.exec("using UndefinedPositive"; append_load_path = [SAMPLES])
    @test !success(proc)
    @test occursin("Following API is declared but not defined", proc.stderr)
    @test occursin("WILL_NOT_BE_DEFINED", proc.stderr)
    @test !occursin("WILL_BE_DEFINED", proc.stderr)
end

function test_strict_negative()
    proc = Utils.exec("using StrictNegative"; append_load_path = [SAMPLES])
    @test success(proc)
end

function test_strict_positive()
    proc = Utils.exec("using StrictPositive"; append_load_path = [SAMPLES])
    @test !success(proc)
    @test occursin("Non-public API imported", proc.stderr)
end

end  # module
