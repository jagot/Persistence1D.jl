module Persistence1D

include("../deps/deps.jl")

function find_persistence(v::Array{Float32},
                          threshold = 0,
                          persistence = true)
    v = convert(Array{Float32}, v)

    min_p = Ref{Ptr{Cint}}(0)
    max_p = Ref{Ptr{Cint}}(0)
    nmin = Ref{Csize_t}(0)
    nmax = Ref{Csize_t}(0)
    gminvalue = Ref{Cfloat}(0)
    pers_p,npers = persistence ? (Ref{Ptr{Cfloat}}(0),Ref{Csize_t}(1)) : (C_NULL,Ref{Csize_t}(0))

    ccall((:find_extrema, _jl_libpersistence1d),
          Void,
          (Ptr{Cfloat}, Csize_t,
           Ref{Ptr{Cint}}, Ref{Csize_t},
           Ref{Ptr{Cint}}, Ref{Csize_t},
           Ref{Cfloat},
           Ref{Ptr{Cfloat}}, Ref{Csize_t},
           Cfloat),
          v, length(v),
          min_p, nmin,
          max_p, nmax,
          gminvalue,
          pers_p, npers,
          threshold)

    nmin = convert(Int64,nmin[])
    nmax = convert(Int64,nmax[])
    min_v = unsafe_wrap(Array,min_p[], nmin, true)
    max_v = unsafe_wrap(Array,max_p[], nmax, true)

    persistence || return min_v, max_v
    npers = convert(Int64,npers[])
    pers_v = unsafe_wrap(Array,pers_p[], npers, true)
    min_v,max_v,convert(Float32,gminvalue[]),pers_v
end

find_persistence{T<:Real}(v::Array{T}, threshold = 0, persistence = true) =
    find_persistence(convert(Array{Float32}, v), threshold, persistence)

find_extrema{T<:Real}(v::Array{T}, threshold = 0) =
    find_persistence(v, threshold, false)

export find_persistence, find_extrema

end
