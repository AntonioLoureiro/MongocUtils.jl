using Test
using Mongoc,MongocUtils

struct Tvalue
   id::String
end

struct TestM
    id::String
    i::Int64
    a::Array{Dict,1}
    vt::Vector
    t::Tvalue
end

t1=TestM("aa", 1, [Dict("aa"=>1),Dict("c"=>"tt")],[Tvalue("tt")], Tvalue("tt"))
bt=Mongoc.BSON(t1)

@test bt["id"]=="aa"
@test bt["i"]==1
@test bt["a"]==[Dict("aa" => 1), Dict("c" => "tt")]
@test bt["vt"][1]["id"]=="tt"
@test bt["t"]==Dict("id"=>"tt")

module md

abstract type abs end

struct nest_st
    s::String
    nb::Number
    u::Union{String,Number}
    v::Vector
    z
end

struct st<:abs
    s::String
    nb::Number
    u::Union{String,Number}
    v::Vector
    ns::nest_st
    z
end

end

inst=md.st("T",123,123.123,[md.nest_st("T",100.10,200,[],"Any"),Dict("a"=>100,"b"=>"test")],md.nest_st("T",100.10,200,[23,"aa"],"Any"),Dict("a"=>100))
bson=Mongoc.BSON(inst)
inst_st=as_struct(md.st,bson)
@test inst_st.s=="T"
@test inst_st.u==123.123
@test inst_st.v[1].s=="T"
@test inst_st.v[2]==Dict("a"=>100,"b"=>"test")
@test inst_st.ns.s=="T"
@test inst_st.z==Dict("a"=>100)

@time inst_st=as_struct(md.abs,bson)
@test inst_st.ns.s=="T"