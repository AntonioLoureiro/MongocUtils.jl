const BSON_PRIMITIVE=Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSON,Type,Dict,Mongoc.BSONCode,Date,Vector{UInt8},Nothing,Enum}

## Type
function Base.setindex!(d::Mongoc.BSON,tv::Type,st::AbstractString)
    d[st]=Dict("_type"=>"Type","_value"=>string(tv))
end

## Date
Base.setindex!(d::Mongoc.BSON,tv::Date,st::String)=d[st]=DateTime(tv)

## Enum
Base.setindex!(d::Mongoc.BSON,tv::Enum,st::String)=d[st]=Int(tv)
Mongoc.BSON(s::BSON_PRIMITIVE)=s
Mongoc.BSON(s::Enum)=Int(s)

function Base.setindex!(d::Mongoc.BSON,tv::Dict,st::String)
    if keytype(tv)<:AbstractString    
        setindex!(d, BSON(tv), st)
    else
        return d[st]=Dict("_type"=>string(typeof(tv)),"_value"=>[Dict("_k"=>Mongoc.BSON(k),"_v"=>Mongoc.BSON(v)) for (k,v) in tv])
    end
end


macro BSON(datatype,arr_f)
    arr_f=@eval($arr_f)
    constr_ex_arr=[]
    for f in arr_f    
        push!(constr_ex_arr,"\""*string(f)*"\"=>getfield(s,:$f)")   
    end
    ## _type
    push!(constr_ex_arr,"\"_type\"=>\"$datatype\"")
    
    ex=Meta.parse("try Mongoc.BSON("*join(constr_ex_arr,",")*") catch; BSON_fallback(s) end")

    return quote
        function Mongoc.BSON(s::$(esc(datatype)))    
            return $ex
        end
    end 
end

macro BSON_setindex(datatype)
    
    return quote
        function Base.setindex!(d::Mongoc.BSON,tv::$(esc(datatype)),st::AbstractString)
            d[st]=Mongoc.BSON(tv)
            return nothing
        end
    end 
end


function naiveBSON(s)
    document=Mongoc.BSON()
    ts=typeof(s)
    fs=fieldnames(ts)
    for f in fs
        v=getfield(s,f)
        if v isa BSON_PRIMITIVE
            document[string(f)]=v
        elseif v isa Vector
            document[string(f)]=[r isa BSON_PRIMITIVE ? r : naiveBSON(r) for r in v]
        else
            document[string(f)]=naiveBSON(v)
        end
    end
    ## _type
    document["_type"]=string(ts)
    
    return document
end

Mongoc.BSON(s)=BSON_fallback(s)

function BSON_fallback(s)
    curr_mod=Main
    ts=typeof(s)
    fs=fieldnames(ts)
    for f in fs
        tnf=typeof(getfield(s,f))
        fnf=fieldnames(tnf)
        if !(hasmethod(setindex!,Tuple{Mongoc.BSON,tnf,String}))
            Core.eval(curr_mod,Meta.parse("@BSON($tnf,$fnf)"))
            Core.eval(curr_mod,Meta.parse("@BSON_setindex($tnf)"))
        end
    end
    
    Core.eval(curr_mod,Meta.parse("@BSON($ts,$fs)"))
    Core.eval(curr_mod,Meta.parse("@BSON_setindex($ts)"))
    return naiveBSON(s)
end
