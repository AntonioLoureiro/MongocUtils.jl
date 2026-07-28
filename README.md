# MongocUtils.jl

Utilities for converting Julia structs to `Mongoc.BSON` documents and reconstructing typed Julia values from BSON.

## Installation

```julia
using Pkg
Pkg.add("MongocUtils")
```

## Write a struct to BSON

```julia
using Mongoc
using MongocUtils

struct Tvalue
    id::String
end

struct Example
    id::String
    count::Int
    attributes::Vector{Dict}
    values::Vector
    nested::Tvalue
end

value = Example(
    "aa",
    1,
    [Dict("aa" => 1), Dict("c" => "tt")],
    [Tvalue("tt")],
    Tvalue("tt"),
)

document = Mongoc.BSON(value)
```

`document` is a normal `Mongoc.BSON` value and can be inserted into MongoDB using Mongoc.jl.

## Read BSON into a struct

```julia
restored = as_struct(Example, document)
```

The stored `_type` metadata is used for nested concrete values, abstract fields, symbols, enums, dictionaries with non-string keys, and heterogeneous arrays.

## Custom construction

By default, `as_struct` calls a type's positional constructor using fields in declaration order. Types with validation, keyword-only construction, or no matching positional constructor can define a `construct` method:

```julia
struct PositiveValue
    value::Int
    PositiveValue(value::Int, ::Val{:validated}) =
        value > 0 ? new(value) : throw(ArgumentError("value must be positive"))
end

MongocUtils.construct(::Type{PositiveValue}, fields::NamedTuple) =
    PositiveValue(fields.value, Val(:validated))
```

The `NamedTuple` keys are the struct field names, so custom construction does not depend on manual dictionary lookups.

## Supported values

MongocUtils handles common BSON-compatible values, including numbers, strings, dates, object IDs, byte vectors, enums, symbols, nested structs, arrays, and dictionaries.

## Testing

```julia
using Pkg
Pkg.test("MongocUtils")
```
