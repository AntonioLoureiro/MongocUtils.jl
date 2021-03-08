# MongocUtils.jl
## Write to Mongo
```julia
using Mongoc,MongocUtils

struct Tvalue
   id::String
end

struct Test
    id::String
    i::Int64
    a::Array{Dict,1}
    vt::Vector
    t::Tvalue
end

t1=Test("aa", 1, [Dict("aa"=>1),Dict("c"=>"tt")],[Tvalue("tt")], Tvalue("tt"))
bs=Mongoc.BSON(t1)
Mongoc.BSON with 5 entries:
  "id" => "aa"
  "i"  => 1
  "a"  => Any[Dict{Any,Any}("aa"=>1), Dict{Any,Any}("c"=>"tt")]
  "vt" => Any[Dict{Any,Any}("id"=>"tt")]
  "t"  => Dict{Any,Any}("id"=>"tt")
  ```
## Read from Mongo
```julia
as_struct(Test,bs)
Test("aa", 1, Dict[Dict("aa" => 1), Dict("c" => "tt")], Tvalue[Tvalue("tt")], Tvalue("tt"))
  ```