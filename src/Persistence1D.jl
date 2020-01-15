module Persistence1D

include("../deps/deps.jl")

struct Persistence{T}
    data::Vector{T}
    minima::Vector{Int}
    maxima::Vector{Int}
    gminindex::Int
    gminvalue::T
    persistence::Vector{T}
end

function find_persistence(v::Array{Float32},
                          threshold = 0,
                          persistence = true)
    min_p = Ref{Ptr{Cint}}(0)
    max_p = Ref{Ptr{Cint}}(0)
    nmin = Ref{Csize_t}(0)
    nmax = Ref{Csize_t}(0)
    gminindex,gminvalue = Ref{Cint}(0),Ref{Cfloat}(0)
    pers_p,npers = persistence ? (Ref{Ptr{Cfloat}}(0),Ref{Csize_t}(1)) : (C_NULL,Ref{Csize_t}(0))

    ccall((:find_extrema, _jl_libpersistence1d),
          Cvoid,
          (Ptr{Cfloat}, Csize_t,
           Ref{Ptr{Cint}}, Ref{Csize_t},
           Ref{Ptr{Cint}}, Ref{Csize_t},
           Ref{Cint}, Ref{Cfloat},
           Ref{Ptr{Cfloat}}, Ref{Csize_t},
           Cfloat),
          v, length(v),
          min_p, nmin,
          max_p, nmax,
          gminindex, gminvalue,
          pers_p, npers,
          threshold)

    nmin = convert(Int64,nmin[])
    nmax = convert(Int64,nmax[])
    min_v = unsafe_wrap(Array,min_p[], nmin, own=true)
    max_v = unsafe_wrap(Array,max_p[], nmax, own=true)

    gminindex,gminvalue = convert(Int32,gminindex[]),convert(Float32,gminvalue[])

    persistence || return [min_v;gminindex],max_v
    npers = convert(Int64,npers[])
    pers_v = unsafe_wrap(Array,pers_p[], npers, own=true)
    Persistence(v, min_v, max_v, gminindex, gminvalue, pers_v)
end

find_persistence(v::Array{T}, threshold = 0, persistence = true) where {T<:Real} =
    find_persistence(convert(Array{Float32}, v), threshold, persistence)

find_extrema(v::Array{T}, threshold = 0) where {T<:Real} =
    find_persistence(v, threshold, false)

import Base.filter
function filter(p::Persistence, threshold::Real)
    pis = find(p.persistence .> threshold)
    Persistence(p.data,
                p.minima[pis],
                p.maxima[pis],
                p.gminindex,
                p.gminvalue,
                p.persistence[pis])
end

export find_persistence, find_extrema, filter

include("reconstruct.jl")

end
