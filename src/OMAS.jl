module OMAS

import IMAS
import PythonCall

mutable struct ODS
    ids::Union{Nothing,<:IMAS.IDS,<:IMAS.IDSvector}
    cocosio::Int
    coordsio::Dict{String,Any}
    unitsio::Bool
    uncertainio::Bool
end

"""
    ODS()

Constructor with default values for .cocosio, .coordsio, .unitsio, .uncertainio
"""
function ODS()
    return ODS(nothing, IMAS.IMASdd.internal_cocos, Dict{String,Any}(), false, false)
end

"""
    ODS(ids::Union{Nothing,<:IMAS.IDS,<:IMAS.IDSvector}, ods::ODS)

Constructor that copies over values of ods.cocosio, ods.coordsio, ods.unitsio, ods.uncertainio from input ods
"""
function ODS(ids::Union{Nothing,<:IMAS.IDS,<:IMAS.IDSvector}, ods::ODS)
    return ODS(ids, ods.cocosio, ods.coordsio, ods.unitsio, ods.uncertainio)
end

# Implement the OMAS API

function Base.length(ods::ODS)
    if typeof(ods.ids) <: IMAS.IDSvector
        return length(ods.ids)
    else
        return length(keys(ods))
    end
end

function Base.getindex(ods::ODS, key::Int)
    @assert typeof(ods.ids) <: IMAS.IDSvector
    return Base.getindex(ods, [key])
end

function Base.getindex(ods::ODS, key::String)
    return Base.getindex(ods, IMAS.i2p(key))
end

function Base.getindex(ods::ODS, path::Tuple)
    return Base.getindex(ods, collect(path))
end

function Base.getindex(ods::ODS, path::Vector)
    if ods.ids === nothing
        ods.ids = IMAS.dd()
    end
    h = ods.ids
    for p in path
        if typeof(h) <: IMAS.IDSvector
            if typeof(p) <: Int
                pyn = p
            else
                pyn = parse(Int, p)
            end
            if pyn == Base.length(h)
                Base.resize!(h, pyn + 1)
            end
            h = Base.getindex(h, pyn + 1)
        else
            h = getproperty(h, Symbol(p))
        end
    end
    if typeof(h) <: Union{IMAS.IDS,IMAS.IDSvector}
        return ODS(h, ods)
    else
        return h
    end
end

function Base.setindex!(ods::ODS, val, pyn::Int)
    @assert typeof(ods.ids) <: IMAS.IDSvector
    if typeof(val) <: ODS
        val = val.ids
    end
    if pyn == Base.length(ods.ids)
        Base.resize!(ods.ids, pyn + 1)
    end
    return Base.setindex!(ods.ids, val, pyn + 1)
end

function Base.setindex!(ods::ODS, val, key::String)
    path = IMAS.i2p(key)
    h = ods[IMAS.p2i(path[1:end-1])].ids
    field = Symbol(path[end])
    if typeof(val) <: ODS && val.ids === nothing
        empty!(h)
        return val
    else
        if typeof(val) <: ODS
            val = val.ids
        end
        tp = IMAS.concrete_fieldtype_typeof(h, field)
        if !(typeof(val) <: tp)
            val = try
                omas_convert(tp, val)
            catch e
                @show tp
                @show typeof(val)
                @show val
                rethrow(e)
            end
        end
        return Base.setproperty!(h, field, val)
    end
end

function omas_convert(tp::Type, val::Any)
    return convert(tp, val)
end

function omas_convert(tp::Type, val::StepRangeLen)
    return collect(val)
end

function omas_convert(tp::Type, val::Union{PythonCall.Py,PythonCall.PyArray})
    return PythonCall.pyconvert(tp, val)
end

function omas_convert(tp::Type, val::PythonCall.PyDict)
    return IMAS.IMASdd.JSON.json(Dict{String, Any}(val), 1)
end

function Base.keys(ods::ODS)
    if ods.ids === nothing
        return String[]
    elseif typeof(ods.ids) <: IMAS.IDS
        return collect(map(string, IMAS.keys_no_missing(ods.ids)))
    elseif typeof(ods.ids) <: IMAS.IDSvector
        return collect(1:length(ods.ids))
    else
        error("keys(ods::ODS) should never be here")
    end
end

function Base.iterate(ods::ODS)
    allkeys = collect(keys(ods))
    if isempty(allkeys)
        return nothing
    end
    return allkeys[1], (allkeys, 2)
end

function Base.iterate(ods::ODS, state::Tuple{Vector{String},Int})
    allkeys, k = state
    if k > length(allkeys)
        return nothing
    else
        return allkeys[k], (allkeys, k + 1)
    end
end

function ulocation(ods::ODS)
    uloc = IMAS.ulocation(getfield(ods, :ids))
    return replace(uloc, "[" => ".", "]" => "")
end

function location(ods::ODS)
    path = IMAS.i2p(IMAS.location(getfield(ods, :ids)))
    for (k, field) in enumerate(path)
        if isdigit(field[1])
            path[k] = string(parse(Int, field) - 1)
        end
    end
    loc = IMAS.p2i(path)
    return replace(loc, "[" => ".", "]" => "")
end

function Base.getproperty(ods::ODS, field::Symbol)
    if field == :keys
        return () -> keys(ods)
    elseif field in (:cocosio, :coordsio, :unitsio, :uncertainio)
        return getfield(ods, field)
    elseif field == :location
        return location(ods)
    elseif field == :ulocation
        return ulocation(ods)
    else
        return getfield(ods, field)
    end
end

function Base.setproperty!(ods::ODS, field::Symbol, value::Any)
    # cocosio, coordsio, unitsio, uncertainio functionality not implemented
    if field == :cocosio
        @assert value == IMAS.IMASdd.internal_cocos "ods.cocosio functionality not yet implemented"
    elseif field == :coordsio
        @show value
        @assert isempty(value) "ods.coordsio functionality not yet implemented"
    elseif field == :unitsio
        @assert !value "ods.unitsio functionality not yet implemented"
    elseif field == :uncertainio
        @assert !value "ods.uncertainio functionality not yet implemented"
    end
    return setfield!(ods, field, value)
end

export ODS

end
