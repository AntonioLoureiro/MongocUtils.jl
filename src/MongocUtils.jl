module MongocUtils

using Mongoc,Dates
import Base.setindex!
import Mongoc.BSON

export @BSON,@BSON_setindex

const BSON_PRIMITIVE=Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSON,Dict,Vector,Mongoc.BSONCode,Date,Vector{UInt8},Nothing}

Base.setindex!(d::Mongoc.BSON,tv::Date,st::String)=d[st]=DateTime(tv)

macro BSON(datatype,arr_f)
    arr_f=@eval($arr_f)
    constr_ex_arr=[]
    for f in arr_f
        push!(constr_ex_arr,"\""*string(f)*"\"=>getfield(s,:$f)")
    end
    ex=Meta.parse("Mongoc.BSON("*join(constr_ex_arr,",")*")")

    return quote
        function Mongoc.BSON(s::$(esc(datatype)))    
            return $ex
        end
    end 
end

macro BSON_setindex(datatype)
    
    return quote
        function Base.setindex!(d::Mongoc.BSON,tv::$(esc(datatype)),st::String)
            d[st]=Mongoc.BSON(tv)
            return nothing
        end
    end 
end

function naiveBSON(s)
    document=Mongoc.BSON()
    fs=fieldnames(typeof(s))
    for f in fs
        v=getfield(s,f)
        if v isa BSON_PRIMITIVE
            document[string(f)]=v
        else
            document[string(f)]=naiveBSON(v)
        end
    end
    
    return document
end

function Mongoc.BSON(s)
    curr_mod=Main
    fs=fieldnames(typeof(s))
    for f in fs
        tnf=typeof(getfield(s,f))
        fnf=fieldnames(tnf)
        if !(hasmethod(setindex!,Tuple{Mongoc.BSON,tnf,String}))
            Core.eval(curr_mod,Meta.parse("@BSON($tnf,$fnf)"))
            Core.eval(curr_mod,Meta.parse("@BSON_setindex($tnf)"))
        end
    end
    ts=typeof(s)
    Core.eval(curr_mod,Meta.parse("@BSON($ts,$fs)"))
    Core.eval(curr_mod,Meta.parse("@BSON_setindex($ts)"))
    return naiveBSON(s)
end

end
