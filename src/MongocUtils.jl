module MongocUtils

using Mongoc, Dates, InteractiveUtils, RuntimeGeneratedFunctions
import Base.setindex!
import Mongoc.BSON

RuntimeGeneratedFunctions.init(@__MODULE__)

export as_struct

const BSON_PRIMITIVE = Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSON,Type,Dict,Mongoc.BSONCode,Date,Vector{UInt8},Nothing,Enum}
const BSON_VALUE_PRIMITIVE = Union{Mongoc.BSONObjectId,Number,AbstractString,DateTime,Mongoc.BSONCode,Date,Vector{UInt8},Nothing}

include("BSON.jl")
include("as_struct.jl")

end
