# MongocUtils.jl
```julia
struct Tvalue
   id::String
end

struct Test
    id::String
    i::Int64
    a::Array{Dict,1}
    t::Tvalue
end

t1=Test("aa", 1, [Dict("aa"=>1), Dict("b"=>2)], Tvalue("tt"))
Mongoc.BSON(t1) => BSON("{"id" => "aa", "i"  => 1, "a"  => Any[Dict{Any,Any}("aa"=>1), Dict{Any,Any}("b"=>2)],"t"  => Dict{Any,Any}("id"=>"tt"))
```
