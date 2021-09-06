baremodule PublicAPI

module Internal

using ..PublicAPI: PublicAPI

include("internal.jl")

end  # module Internal

end  # baremodule PublicAPI
