module MongocUtils

using Mongoc,Dates
import Base.setindex!
import Mongoc.BSON

export @BSON,@BSON_setindex
export as_struct

const BSON_PRIMITIVE=Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSON,Dict,Mongoc.BSONCode,Date,Vector{UInt8},Nothing,Enum}

## Date
Base.setindex!(d::Mongoc.BSON,tv::Date,st::String)=d[st]=DateTime(tv)

## Enum
Base.setindex!(d::Mongoc.BSON,tv::Enum,st::String)=d[st]=Int(tv)
Mongoc.BSON(s::Enum)=Int(s)

include("BSON.jl")
include("as_struct.jl")

end
