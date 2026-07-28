using Test

module X

    module E
        using MongocUtils, Mongoc

        struct N
            x::Int64
        end

        function a()
            n = N(1)
            return Mongoc.BSON(n)
        end
    end

    function b()
        n = E.N(2)
        return E.Mongoc.BSON(n)
    end
end

n = X.E.a()
n_st = X.E.as_struct(X.E.N, n)
@test n_st.x == 1

n = X.b()
n_st = X.E.as_struct(X.E.N, n)
@test n_st.x == 2

module CustomConstruction
    using MongocUtils, Mongoc

    struct ValidatedValue
        value::Int
        ValidatedValue(value::Int, ::Val{:validated}) = value > 0 ? new(value) : throw(ArgumentError("value must be positive"))
    end

    MongocUtils.construct(::Type{ValidatedValue}, fields::NamedTuple) =
        ValidatedValue(fields.value, Val(:validated))
end

custom_bson = Mongoc.BSON("value" => 42, "_type" => "ValidatedValue")
custom_value = MongocUtils.as_struct(CustomConstruction.ValidatedValue, custom_bson)
@test custom_value.value == 42
