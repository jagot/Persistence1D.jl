module Persistence1D

include("../deps/deps.jl")

function find_extrema(v::Array{Float32}, threshold = 0)
    v = convert(Array{Float32}, v)

    min_p = Ref{Ptr{Cint}}(0)
    max_p = Ref{Ptr{Cint}}(0)
    nmin = Ref{Csize_t}(0)
    nmax = Ref{Csize_t}(0)

    ccall((:find_extrema, _jl_libpersistence1d),
          Void,
          (Ptr{Cfloat}, Csize_t,
           Ref{Ptr{Cint}}, Ref{Csize_t},
           Ref{Ptr{Cint}}, Ref{Csize_t},
           Cfloat),
          v, length(v),
          min_p, nmin,
          max_p, nmax,
          threshold)

    nmin = convert(Int64,nmin[])
    nmax = convert(Int64,nmax[])
    min_v = pointer_to_array(min_p[], nmin, true)
    max_v = pointer_to_array(max_p[], nmax, true)

    min_v, max_v
end

end