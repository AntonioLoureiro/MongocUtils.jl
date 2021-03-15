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
@test bt["t"]["id"]=="tt"

## Second run after method definition
t1=TestM("aa", 1, [Dict("aa"=>1),Dict("c"=>"tt")],[Tvalue("tt")], Tvalue("tt"))
bt=Mongoc.BSON(t1)

@test bt["id"]=="aa"
@test bt["i"]==1
@test bt["a"]==[Dict("aa" => 1), Dict("c" => "tt")]
@test bt["vt"][1]["id"]=="tt"
@test bt["t"]["id"]=="tt"

module md

abstract type abs end
@enum Color red blue green

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
    e::Color
    v::Vector
    ns::nest_st
    z
end

struct std<:abs
    d1::Dict
    d2::Dict
    d3::Dict{String,Int64}
    d4::Dict{Int64,Int64}
    d5::Dict{Int64,nest_st}
    d6
end

end
dict_complex=Dict("a"=>"a",1=>1,2=>md.nest_st("T",100.10,200,[23,"aa"],"Any"))

inst=md.st("T",123,123.123,md.red,[md.nest_st("T",100.10,200,[],"Any"),Dict("a"=>100,"b"=>"test")],md.nest_st("T",100.10,200,[23,"aa"],"Any"),Dict("a"=>100))
bson=Mongoc.BSON(inst)
inst_st=as_struct(md.st,bson)
@test inst_st.s=="T"
@test inst_st.u==123.123
@test inst_st.v[1].s=="T"
@test inst_st.v[2]==Dict("a"=>100,"b"=>"test")
@test inst_st.ns.s=="T"
@test inst_st.z==Dict("a"=>100)
@test inst_st.e==md.red

## Construction with Abstract Type
@time inst_st=as_struct(md.abs,bson)
@test inst_st.ns.s=="T"

## Dicts
inst=md.std(Dict("ff"=>"ff"),Dict(1=>md.nest_st("T",100.10,200,[],"Any")),Dict("a"=>1),Dict(1=>1),Dict(1=>md.nest_st("T",100.10,200,[],"Any")),dict_complex)
bson=Mongoc.BSON(inst)

inst_st=as_struct(md.std,bson)
@test inst_st.d1==Dict("ff"=>"ff")
@test inst_st.d2[1] isa md.nest_st
@test inst_st.d4[1]==1
@test inst_st.d5[1] isa md.nest_st
@test inst_st.d6[1]==1
@test inst_st.d6[2] isa md.nest_st

inst_st=as_struct(md.abs,bson)
@test inst_st.d1==Dict("ff"=>"ff")
@test inst_st.d2[1] isa md.nest_st
@test inst_st.d4[1]==1
@test inst_st.d5[1] isa md.nest_st
@test inst_st.d6[1]==1
@test inst_st.d6[2] isa md.nest_st

## Complex, Dict with non string keys and datatypes
mutable struct complexStruct{T}  
    a::T
    b::String
    d::Dict
    v::Vector{Int64}
    t::Type
    ta
end

p1=complexStruct{Int64}(1,"t",Dict("1"=>md.nest_st("T",100.10,200,[],"Any")),[1,2,3],Float64,Number)

bs=Mongoc.BSON(p1)
inst_st=as_struct(complexStruct{Int64},bs)
@test inst_st.t==Float64
@test inst_st.d["1"] isa md.nest_st


p1=complexStruct{Int64}(1,"t",Dict(1=>md.nest_st("T",100.10,200,[],"Any")),[1,2,3],md.st,md.st)
bs=Mongoc.BSON(p1)
inst_st=as_struct(complexStruct{Int64},bs)
@test inst_st.t==md.st
@test inst_st.d[1] isa md.nest_st

## Dict
bson=Mongoc.BSON(Dict("a"=>md.nest_st("T",100.10,200,[],"Any"),"b"=>100,1=>1,2=>md.nest_st("T",100.10,200,[],"Any"),3=>Dict(2=>1)))
d=as_struct(Dict,bson)
@test d[2] isa Main.md.nest_st
@test d["a"] isa Main.md.nest_st
@test d[3][2]==1
@test d[1]==1