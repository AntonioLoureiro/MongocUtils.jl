
as_struct(dt::Type{T} where T,x::BSON_VALUE_PRIMITIVE)=x
as_struct(dt::Type{T} where T<:Enum,x::BSON_VALUE_PRIMITIVE)=dt(x)
as_struct(dt::Type{T} where T<:Symbol,x::BSON_VALUE_PRIMITIVE)=dt(x)

as_struct(dt::Type{T} where T, arr::Array)=map(x->as_struct(Any,x),arr)

function as_struct(dt::Type{T} where T<:AbstractDict,x)
    _type=haskey(x,"_type") ? str_to_type(x["_type"]) : Dict{Any,Any}
    ret=_type()
    for (k,v) in x
        k=="_type" ? continue : nothing
        if v isa AbstractDict && haskey(v,"_k") && haskey(v,"_v")
            if v["_k"] isa AbstractDict && haskey(v["_k"],"_type")
               kc=as_struct(str_to_type(v["_k"]["_type"]),v["_k"])
            else
               kc=as_struct(Any,v["_k"])
            end

            if v["_v"] isa AbstractDict && haskey(v["_v"],"_type")
               vc=as_struct(str_to_type(v["_v"]["_type"]),v["_v"])
            else
                vc=as_struct(Any,v["_v"])
            end
            ret[kc]=vc
        elseif v isa AbstractDict && haskey(v,"_type")
            ret[k]=as_struct(str_to_type(v["_type"]),v)
        else
            ret[k]=as_struct(Any,v)
        end
    end

    return ret
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
    ex=Meta.parse(str)
    
    if ex isa Symbol
        curr_module = isdefined(parentmodule(@__MODULE__), ex) ? parentmodule(@__MODULE__) : Main
        return getfield(curr_module,ex)
    elseif ex isa Expr
        if ex.head==:.
            namespace_arr=split(string(ex.args[1]),".")
            curr_module = isdefined(parentmodule(@__MODULE__), Symbol(first(namespace_arr))) ? parentmodule(@__MODULE__) : Main
            for n in namespace_arr
                curr_module=getfield(curr_module,Symbol(n))
            end
            return getfield(curr_module,ex.args[2].value)
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

function as_struct(dt::Type,x)
    
    _type=haskey(x,"_type") ? x["_type"] : nothing
    
    if dt<:Type
        return str_to_type(get(x,"_value",nothing))
    elseif dt<:AbstractDict
        return as_struct(dt,x)
    elseif dt<:MongocUtils.BSON_PRIMITIVE
        return x 
    elseif _type=="Symbol"
        return Symbol(x["_value"])
    elseif isconcretetype(dt)
        return dt([as_struct(fieldtype(dt,k),x[string(k)]) for k in fieldnames(dt)]...)
    elseif dt==Any   
        if _type==nothing
            if x isa AbstractDict
                return as_struct(Dict,x)
            else
                return x
            end
        else
            return as_struct(str_to_type(_type),x)
        end
    ## dt is abstract
    else
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
            stored_type=str_to_type(_type)
            @assert stored_type<:dt "Stored $(string(stored_type)) is not a subtype of abstract type $(string(dt))"
            return as_struct(stored_type,x)
        end
    end
end    
