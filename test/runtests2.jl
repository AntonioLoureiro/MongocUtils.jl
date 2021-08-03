using Test

module X
    using MongocUtils, Mongoc

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
        return Mongoc.BSON(n)
    end
end

n = X.E.a()
n_st = X.E.as_struct(X.E.N, n)
@test n_st.x == 1

n = X.b()
n_st = X.as_struct(X.E.N, n)
@test n_st.x == 2
##
