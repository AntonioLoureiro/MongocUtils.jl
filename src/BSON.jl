## Type
function Base.setindex!(d::Mongoc.BSON, tv::Type, st::AbstractString)
    d[st] = Dict("_type" => "Type", "_value" => string(nameof(tv)))
end

## Date
Base.setindex!(d::Mongoc.BSON, tv::Date, st::String) = d[st] = DateTime(tv)

## Enum
Base.setindex!(d::Mongoc.BSON, tv::Enum, st::String) = d[st] = Int(tv)
Mongoc.BSON(s::BSON_VALUE_PRIMITIVE) = s

Mongoc.BSON(s::Enum) = Int(s)
Mongoc.BSON(s::Symbol) = Dict("_type" => "Symbol", "_value" => string(s))

function Base.setindex!(d::Mongoc.BSON, tv::BSON_VALUE_PRIMITIVE, st)
    d[string(hash(st), base = 62)] = Dict("_k" => Mongoc.BSON(st), "_v" => tv)
end

function Base.setindex!(d::Mongoc.BSON, tv, st)
    # Important for Dicts with st String but no method already defined for tv
    if st isa AbstractString
        d[st] = Mongoc.BSON(tv)
    elseif tv isa Vector
        d[string(hash(st), base = 62)] = Dict(
            "_k" => Mongoc.BSON(st),
            "_v" => map(x -> x isa BSON_VALUE_PRIMITIVE ? x : Mongoc.BSON(x), tv),
        )
    else
        d[string(hash(st), base = 62)] = Dict("_k" => Mongoc.BSON(st), "_v" => Mongoc.BSON(tv))
    end
end

str_datatype(datatype::DataType) = string(nameof(datatype))

naiveBSON(s::BSON_PRIMITIVE) = s
naiveBSON(s::Vector) = naiveBSON.(s)
naiveBSON(s::Symbol) = Mongoc.BSON("_type" => "Symbol", "_value" => string(s))

function naiveBSON(s)
    document = Mongoc.BSON()
    ts = typeof(s)
    document["_type"] = str_datatype(ts)

    for f in fieldnames(ts)
        v = getfield(s, f)
        if !hasmethod(Mongoc.BSON, Tuple{typeof(v)}) || v isa MongocUtils.BSON_PRIMITIVE || v isa AbstractArray
            document[string(f)] = MongocUtils.naiveBSON(v)
        else
            document[string(f)] = Mongoc.BSON(v)
        end
    end

    return document
end

const BSON_FUNCTIONS = Dict{DataType,Any}()
const BSON_FUNCTIONS_LOCK = ReentrantLock()

function build_bson_function(datatype::DataType)
    pairs = Any[
        :($(string(f)) => getfield(s, $(QuoteNode(f))))
        for f in fieldnames(datatype)
    ]
    push!(pairs, :("_type" => $(str_datatype(datatype))))

    bson_call = Expr(:call, :(Mongoc.BSON), pairs...)
    expression = :(s -> begin
        try
            $bson_call
        catch
            MongocUtils.naiveBSON(s)
        end
    end)

    return RuntimeGeneratedFunctions.RuntimeGeneratedFunction(
        MongocUtils,
        MongocUtils,
        expression,
    )
end

function bson_function(datatype::DataType)
    lock(BSON_FUNCTIONS_LOCK) do
        return get!(BSON_FUNCTIONS, datatype) do
            build_bson_function(datatype)
        end
    end
end

Mongoc.BSON(s) = BSON_fallback(s)
BSON_fallback(s) = bson_function(typeof(s))(s)

function whereis(mod::Symbol, parent::Module)
    arr = names(parent, all = true)
    if isdefined(parent, mod)
        return parent
    else
        for r in arr
            r in [nameof(parent), :Base, :Core] ? continue : nothing
            sub = getproperty(parent, r)
            sub isa Module ? nothing : continue
            found = whereis(mod, sub)
            if found !== nothing
                return found
            end
        end
    end
    return Main
end
