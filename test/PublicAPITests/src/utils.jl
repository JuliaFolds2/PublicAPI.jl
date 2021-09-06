module Utils

struct CompletedProcess
    stdout::String
    stderr::String
    proc::Base.Process
end

function open_stdin_new(f, cmd)
    out = IOBuffer()
    err = IOBuffer()
    cmd = pipeline(cmd; stderr = err, stdout = out)
    proc = open(cmd, write = true) do proc
        f(proc)
        return proc
    end
    completed = CompletedProcess(String(take!(out)), String(take!(err)), proc)
end

function open_stdin_old(f, cmd)
    inp = Pipe()
    out = Pipe()
    err = Pipe()
    cmd = pipeline(cmd; stdin = inp, stdout = out, stderr = err)
    proc = run(cmd; wait = false)
    close(out.in)
    close(err.in)
    outstr = Ref{String}()
    errstr = Ref{String}()
    @sync begin
        @async outstr[] = read(out, String)
        @async errstr[] = read(err, String)
        try
            f(inp)
        finally
            close(inp)
        end
        wait(proc)
    end
    return CompletedProcess(outstr[], errstr[], proc)
end

if VERSION < v"1.3-"
    open_stdin(args...) = open_stdin_old(args...)
else
    open_stdin(args...) = open_stdin_new(args...)
end

function exec(
    code;
    append_load_path::Union{Nothing,AbstractVector{<:AbstractString}} = nothing,
)
    julia = Base.julia_cmd()
    script = "include_string(Main, read(stdin, String))"
    cmd = `$julia --startup-file=no -e $script`
    setup = Base.load_path_setup_code()
    cmd = ignorestatus(cmd)
    completed = open_stdin(cmd) do input
        write(input, setup)
        println(input)
        if append_load_path !== nothing
            println(input, "append!(LOAD_PATH, $(repr(collect(append_load_path))))")
            println(input)
        end
        write(input, code)
        close(input)
    end
    @debug(
        "Done `exec(code)`",
        code = Text(code),
        stdout = Text(completed.stdout),
        stderr = Text(completed.stderr),
    )
    return completed
end

Base.success(c::CompletedProcess) = success(c.proc)

end  # module
