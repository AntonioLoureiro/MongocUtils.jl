const BSON_VALUE_PRIMITIVE=Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSONCode,Date,Vector{UInt8},Nothing}

as_struct(dt::Type, x)=x
as_struct(dt::Type, x::Dict)=as_struct(dt, Mongoc.BSON(x))
function as_struct(dt::Type, x::Mongoc.BSON)
    
    if isconcretetype(dt)
       return dt([convert_bson_value(fieldtype(dt,k),x[string(k)]) for k in fieldnames(dt)]...)
    else
         _type=nothing
        try _type=get(x,"_type",nothing) catch; end
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
            return as_struct(str_to_type(_type),x)
        end
    end
end

convert_bson_value(dt::DataType,x::BSON_VALUE_PRIMITIVE)=x
convert_bson_value(dt::Union,x::BSON_VALUE_PRIMITIVE)=x
convert_bson_value(dt::UnionAll,x::BSON_VALUE_PRIMITIVE)=x
convert_bson_value(dt::Type{T} where T<:Enum,x::BSON_VALUE_PRIMITIVE)=dt(x)

convert_bson_value(dt::Type{Array{T,1} where T}, arr::Array)=map(x->convert_bson_value(eltype(dt),x),arr)
convert_bson_value(dt::Type{T} where T<:AbstractDict,x)=x

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

function str_to_type(str::String)
    curr_model=Main
    str_arr=split(str,".")
    if length(str_arr)==1    
        return getfield(curr_model,Symbol(str))
    else
        for r in str_arr[1:end-1]
            curr_model=getfield(curr_model,Symbol(r))
        end
        return getfield(curr_model,Symbol(str_arr[end]))
    end
end

function convert_bson_value(dt::Type,x)
    
    if dt<:MongocUtils.BSON_PRIMITIVE
        return x 
    elseif isconcretetype(dt)
        return as_struct(dt,x)
    elseif dt==Any
        _type=nothing
        try _type=get(x,"_type",nothing) catch; end
        if _type==nothing
            return x
        else
            return convert_bson_value(str_to_type(_type),x)
        end
    else
        _type=nothing
        try _type=get(x,"_type",nothing) catch; end
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
            return convert_bson_value(str_to_type(_type),x)
        end
    end
end    
