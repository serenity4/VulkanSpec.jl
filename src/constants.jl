"""
Specification for a constant.
"""
struct SpecConstant <: Spec
    "Name of the constant."
    name::Symbol
    "Value of the constant."
    value::Any
end

"API constants, usually defined in C with #define."
struct Constants <: Collection{SpecConstant}
  data::data_type(SpecConstant)
end

function follow_constant(spec::SpecConstant, constants::Constants)
  @match val = spec.value begin
      ::Symbol && if haskey(constants, val) end => follow_constant(constants[val], constants)
      _ => val
  end
end

function follow_constant(name, constants::Constants)
  constant = get(constants, name, nothing)
  isnothing(constant) ? name : follow_constant(constant, constants)
end

"""
Specification for an enumeration type.
"""
struct SpecEnum <: Spec
    "Name of the enumeration type."
    name::Symbol
    "Vector of possible enumeration values."
    enums::StructVector{SpecConstant}
end

"API enumerated values, excluding bitmasks."
struct Enums <: Collection{SpecEnum}
  data::data_type(SpecEnum)
end

"""
Specification for a bit used in a bitmask.
"""
struct SpecBit <: Spec
    "Name of the bit."
    name::Symbol
    "Position of the bit."
    position::Int
end

struct SpecBitCombination <: Spec
    "Name of the bit combination."
    name::Symbol
    "Value of the combination."
    value::Int
end

"""
Specification for a bitmask type that must be formed through a combination of `bits`.

Is usually an alias for a `UInt32` type which carries meaning through its bits.
"""
struct SpecBitmask <: Spec
    "Name of the bitmask type."
    name::Symbol
    "Valid bits that can be combined to form the final bitmask value."
    bits::StructVector{SpecBit}
    combinations::StructVector{SpecBitCombination}
    width::Integer
end

"API bitmasks."
struct Bitmasks <: Collection{SpecBitmask}
  data::data_type(SpecBitmask)
end

"""
Specification for a flag type `name` that is a type alias of `typealias`. Can be associated with a bitmask structure, in which case the `bitmask` number is set to the corresponding `SpecBitmask`.
"""
struct SpecFlag <: Spec
    "Name of the flag type."
    name::Symbol
    "The type it aliases."
    typealias::Symbol
    "Bitmask, if applicable."
    bitmask::Optional{SpecBitmask}
end

"API flags."
struct Flags <: Collection{SpecFlag}
  data::data_type(SpecFlag)
end
