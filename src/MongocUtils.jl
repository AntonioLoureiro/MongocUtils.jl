module MongocUtils

using Mongoc,Dates,InteractiveUtils
import Base.setindex!
import Mongoc.BSON

export @BSON,@BSON_setindex
export as_struct

include("BSON.jl")
include("as_struct.jl")

end
