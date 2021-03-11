const BSON_VALUE_PRIMITIVE=Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSONCode,Date,Vector{UInt8},Nothing}

as_struct(dt::Type, x)=x
as_struct(dt::Type, x::Dict)=as_struct(dt, Mongoc.BSON(x))
function as_struct(dt::Type, x::Mongoc.BSON)
    
    if isconcretetype(dt)
       return dt([convert_bson_value(fieldtype(dt,k),x[string(k)]) for k in fieldnames(dt)]...)
    else
         _type=nothing
        haskey(x,"_type") ? _type=x["_type"] : nothing
        if _type==nothing
            types_arr=get_concrete_types(dt)
            try 
               for t in types_arr
                  return  as_struct(t,x)
               end
            catch;
               return x
            end
        else
            stored_type=str_to_type(_type)
            @assert stored_type<:dt "Stored $(string(stored_type)) is not a subtype of abstract type $(string(dt))"
            return as_struct(stored_type,x)
        end
    end
end

convert_bson_value(dt::DataType,x::BSON_VALUE_PRIMITIVE)=x
convert_bson_value(dt::Union,x::BSON_VALUE_PRIMITIVE)=x
convert_bson_value(dt::UnionAll,x::BSON_VALUE_PRIMITIVE)=x
convert_bson_value(dt::Type{T} where T<:Enum,x::BSON_VALUE_PRIMITIVE)=dt(x)

convert_bson_value(dt::Type{Array{T,1} where T}, arr::Array)=map(x->convert_bson_value(eltype(dt),x),arr)

function convert_bson_value(dt::Type{T} where T<:AbstractDict,x)
       
    _type=get(x,"_type",nothing)
    _value=get(x,"_value",nothing)

    if _type==nothing
       ret=Dict{String,Any}()
        for (k,v) in x
           ret[k]=convert_bson_value(Any,v) 
        end
       return ret
    else
        ret=str_to_type(_type)()
        for r in _value
            k=r["_k"]
            v=r["_v"]
            if k isa AbstractDict && haskey(k,"_type")
               kc=convert_bson_value(str_to_type(k["_type"]),k)
            else
                kc=k
            end
            
            if v isa AbstractDict && haskey(v,"_type")
               vc=convert_bson_value(str_to_type(v["_type"]),v)
            else
                vc=v
            end
            ret[kc]=vc            
        end
        
        return ret
    end
end

function iter_data_types!(ret::Vector{DataType},arr::Vector)
    for r in arr
        if isconcretetype(r)
           push!(ret,r) 
        else
            n_ret=get_concrete_types(r)
            length(n_ret)==0 ? nothing : append!(ret,n_ret)
        end
    end
end

function get_concrete_types(dt::Type)
    ret=Vector{DataType}()
    if typeof(dt)==Union
         iter_data_types!(ret,Base.uniontypes(dt))
    else
        iter_data_types!(ret,InteractiveUtils.subtypes(dt))
    end
    return ret
end

function str_to_type(str::AbstractString)
    curr_model=Main
    ex=Meta.parse(str)
    
    if ex isa Symbol
        return getfield(curr_model,ex)
    elseif ex isa Expr
        if ex.head==:.
            namespace_arr=split(string(ex.args[1]),".")
            for n in namespace_arr
                curr_model=getfield(curr_model,Symbol(n))
            end
            return getfield(curr_model,ex.args[2].value)
        # Parametric
        elseif ex.head==:curly
            dt=str_to_type(string(ex.args[1]))
            parameters=Vector{Type}()
            for e in ex.args[2:end]
               push!(parameters,str_to_type(string(e)))
            end
            return dt{parameters...}
        end
    end
end

function convert_bson_value(dt::Type,x)
    
    if dt<:Type
        return str_to_type(get(x,"_value",nothing))
    elseif dt<:AbstractDict
        return convert_bson_value(dt,x)
    elseif dt<:MongocUtils.BSON_PRIMITIVE
        return x 
    elseif isconcretetype(dt)
        return as_struct(dt,x)
    elseif dt==Any
        _type=nothing
        haskey(x,"_type") ? _type=x["_type"] : nothing
        if _type==nothing
            return x
        else
            return convert_bson_value(str_to_type(_type),x)
        end
    else
        _type=nothing
        haskey(x,"_type") ? _type=x["_type"] : nothing
        if _type==nothing
            types_arr=get_concrete_types(dt)
            try 
               for t in types_arr
                  return  as_struct(t,x)
               end
            catch;
               return x
            end
        elseif _type=="Type"
            return str_to_type(get(x,"_value",nothing))
        else
            return convert_bson_value(str_to_type(_type),x)
        end
    end
end    
