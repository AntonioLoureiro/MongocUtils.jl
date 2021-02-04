using Test
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
bt=Mongoc.BSON(t1)

@test bt["id"]=="aa"
@test bt["i"]==1
@test bt["a"]==[Dict("aa" => 1), Dict("c" => "tt")]
@test bt["vt"]==[Dict("id" => "tt")]
@test bt["t"]==Dict("id"=>"tt")
