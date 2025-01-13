module OMAS

import IMAS

mutable struct ODS
    ids::Union{Nothing,<:IMAS.IDS,<:IMAS.IDSvector}
end

function ODS()
    ODS(nothing)
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
        return ODS(h)
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
    if typeof(val) <: ODS && val.ids === nothing
        empty!(h)
        return val
    else
        if typeof(val) <: ODS
            val = val.ids
        end
        return Base.setproperty!(h, Symbol(path[end]), val)
    end
end

function Base.keys(ods::ODS)
    if ods.ids === nothing
        return String[]
    elseif typeof(ods.ids) <: IMAS.IDS
        return collect(IMAS.keys_no_missing(ods.ids))
    elseif typeof(ods.ids) <: IMAS.IDSvector
        return collect(1:length(ods.ids))
    else
        error("keys(ods::ODS) should never be here")
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
    if field == :ulocation
        return ulocation(ods)
    elseif field == :location
        return location(ods)
    else
        return getfield(ods, field)
    end
end

export ODS

end
