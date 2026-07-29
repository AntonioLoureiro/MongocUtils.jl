using Test
using Mongoc
using MongocUtils
using RuntimeGeneratedFunctions

@testset "Runtime-generated BSON conversion" begin
    struct RuntimeGeneratedValue
        id::String
        count::Int
    end

    value = RuntimeGeneratedValue("generated", 42)
    generated = MongocUtils.bson_function(RuntimeGeneratedValue)

    @test generated isa RuntimeGeneratedFunctions.RuntimeGeneratedFunction
    @test generated === MongocUtils.bson_function(RuntimeGeneratedValue)

    bson = Mongoc.BSON(value)
    @test bson["id"] == "generated"
    @test bson["count"] == 42
    @test bson["_type"] == "RuntimeGeneratedValue"
    @test as_struct(RuntimeGeneratedValue, bson) == value
end
