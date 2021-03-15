module MongocUtils

using Mongoc,Dates,InteractiveUtils
import Base.setindex!
import Mongoc.BSON

export @BSON,@BSON_setindex
export as_struct

const BSON_PRIMITIVE=Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSON,Type,Dict,Mongoc.BSONCode,Date,Vector{UInt8},Nothing,Enum}
const BSON_VALUE_PRIMITIVE=Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSONCode,Date,Vector{UInt8},Nothing}

include("BSON.jl")
include("as_struct.jl")

end
