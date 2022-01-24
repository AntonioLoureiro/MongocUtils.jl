
## Type
function Base.setindex!(d::Mongoc.BSON,tv::Type,st::AbstractString)
    d[st]=Dict("_type"=>"Type","_value"=>string(tv))
end

## Date
Base.setindex!(d::Mongoc.BSON,tv::Date,st::String)=d[st]=DateTime(tv)

## Enum
Base.setindex!(d::Mongoc.BSON,tv::Enum,st::String)=d[st]=Int(tv)
Mongoc.BSON(s::BSON_VALUE_PRIMITIVE)=s

Mongoc.BSON(s::Enum)=Int(s)
Mongoc.BSON(s::Symbol)=Dict("_type"=>"Symbol","_value"=>string(s))

function Base.setindex!(d::Mongoc.BSON,tv::BSON_VALUE_PRIMITIVE,st)
    d[string(hash(st),base = 62)]=Dict("_k"=>Mongoc.BSON(st),"_v"=>tv)
end

function Base.setindex!(d::Mongoc.BSON,tv,st)
    # Important for Dicts with st String but no method already defined for tv
    if st isa AbstractString
        d[st]=Mongoc.BSON(tv)
    elseif tv isa Vector
        d[string(hash(st),base = 62)]=Dict("_k"=>Mongoc.BSON(st),"_v"=>map(x->x isa BSON_VALUE_PRIMITIVE ? x : Mongoc.BSON(x),tv))
    else
        d[string(hash(st),base = 62)]=Dict("_k"=>Mongoc.BSON(st),"_v"=>Mongoc.BSON(tv))
    end
end

function bson_expr(datatype::DataType)
    arr_f=fieldnames(datatype)
    constr_ex_arr=[]
        for f in arr_f    
            push!(constr_ex_arr,"\""*string(f)*"\"=>getfield(s,:$f)")   
        end
        ## _type
        push!(constr_ex_arr,"\"_type\"=>\""*string(datatype)*"\"")
                
    return Meta.parse("function Mongoc.BSON(s::$(string(datatype))) begin return try Mongoc.BSON("*join(constr_ex_arr,",")*") catch; BSON_fallback(s) end end end")
    
end

function bson_setindex_expr(datatype::DataType)
   return Meta.parse("function Base.setindex!(d::Mongoc.BSON,tv::$(string(datatype)),st::AbstractString) begin d[st]=Mongoc.BSON(tv); return nothing end end")
end

naiveBSON(s::BSON_PRIMITIVE)=s
naiveBSON(s::Vector)=naiveBSON.(s)
naiveBSON(s::Symbol)=Mongoc.BSON("_type"=>"Symbol","_value"=>string(s))

function naiveBSON(s)
    document=Mongoc.BSON()
    ts=typeof(s)
    ## _type
    document["_type"]=string(ts)
    fs=fieldnames(ts)
    for f in fs
        v=getfield(s,f)
        document[string(f)]=naiveBSON(v)
    end  
    
    return document
end

Mongoc.BSON(s)=BSON_fallback(s)

function BSON_fallback(s)
    ts = typeof(s)
    call_mod = parentmodule(ts)
    
    fs=fieldnames(ts)
           
    for f in fs
        tnf=typeof(getfield(s,f))
        fnf=fieldnames(tnf)
        if !(hasmethod(setindex!,Tuple{Mongoc.BSON,tnf,String}))
            Core.eval(call_mod,bson_expr(tnf))
            Core.eval(call_mod,bson_setindex_expr(tnf))
        end
    end

    Core.eval(call_mod,bson_expr(ts))
    Core.eval(call_mod,bson_setindex_expr(ts))
    return naiveBSON(s)
end
