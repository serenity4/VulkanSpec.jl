"""
Structure type classification.

Types:
- `STYPE_CREATE_INFO`: holds constructor parameters (structures that end with `CreateInfo`).
- `STYPE_ALLOCATE_INFO`: holds allocator parameters (structures that end with `AllocateInfo`).
- `STYPE_GENERIC_INFO`: holds parameters for another function or structure (structures that end with `Info`, excluding those falling into the previous types).
- `STYPE_DATA`: usually represents user or Vulkan data.
- `STYPE_PROPERTY`: is a property returned by Vulkan in a `returnedonly` structure, usually done through `FTYPE_QUERY` type functions.
"""
@enum StructType STYPE_CREATE_INFO STYPE_ALLOCATE_INFO STYPE_GENERIC_INFO STYPE_DATA STYPE_PROPERTY

"""
Parameter requirement. Applies both to struct members and function parameters.

Requirement types: 
- `OPTIONAL`: may have its default zero (or nullptr) value, acting as a sentinel value (similar to `Nothing` in Julia).
- `REQUIRED`: must be provided, no sentinel value is allowed.
- `POINTER_OPTIONAL`: is a pointer which may be null, but must have valid elements if provided.
- `POINTER_REQUIRED`: must be a valid pointer, but its elements are optional (e.g. are allowed to be sentinel values).
"""
@enum PARAM_REQUIREMENT OPTIONAL REQUIRED POINTER_OPTIONAL POINTER_REQUIRED

PARAM_REQUIREMENT(node::Node) =
  !haskey(node, "optional") || node["optional"] == "false" ? REQUIRED :
  PARAM_REQUIREMENT(findfirst(node["optional"] .== ["true", "false", "true,false", "false,true"]) - 1)

"""
Specification for a structure parameter.
"""
struct SpecStructMember <: Spec
  "Name of the parent structure."
  parent::Symbol
  "Identifier."
  name::Symbol
  "Expression of its idiomatic Julia type."
  type::ExprLike
  "If constant, cannot be mutated by Vulkan functions."
  is_constant::Bool
  "Whether it must be externally synchronized before calling any function which uses the parent structure."
  is_externsync::Bool
  "[`PARAM_REQUIREMENT`](@ref) classification."
  requirement::PARAM_REQUIREMENT
  "Name of the member (of the same structure) which represents its length. `Nothing` for non-vector types."
  len::Optional{ExprLike}
  "Name of the members (of the same structure) it is a length of."
  arglen::Vector{ExprLike}
  "Whether automatic validity documentation is enabled. If false, this means that the member may be an exception to at least one Vulkan convention."
  autovalidity::Bool
end

"""
Iterate through function or struct specification fields from a list of fields.
`list` is a sequence of fields to get through from `root`.
"""
struct FieldIterator
  root::Any
  list::Any
end

function Base.iterate(f::FieldIterator)
  spec = field(f.root, popfirst!(f.list))
  root = struct_by_name(innermost_type(spec.type))
  if isnothing(root)
    isempty(f.list) || error("Failed to retrieve a struct from $spec to continue the list $(f.list)")
    (spec, nothing)
  else
    (spec, FieldIterator(root, f.list))
  end
end

function field(spec, name)
  index = findfirst(==(name), children(spec).name)
  !isnothing(index) || error("Failed to retrieve field $name in $spec")
  children(spec)[index]
end

Base.iterate(_, f::FieldIterator) = iterate(f)
Base.iterate(f::FieldIterator, ::Nothing) = nothing
Base.length(f::FieldIterator) = length(f.list)

"""
Specification for a structure.
"""
struct SpecStruct <: Spec
  "Name of the structure."
  name::Symbol
  "[`StructType`](@ref) classification."
  type::StructType
  """
  Whether the structure is only meant to be filled in by Vulkan functions, as opposed
  to being constructed by the user.

  Note that the API may still request the user to provide an initialized structure,
  notably as part of `pNext` chains for queries.
  """
  is_returnedonly::Bool
  "Name of the structures it extends, usually done through the original structures' `pNext` argument."
  extends::Vector{Symbol}
  "Structure members."
  members::StructVector{SpecStructMember}
end

children(spec::SpecStruct) = spec.members
iscreateinfo(spec::SpecStruct) = in(spec.type, (STYPE_CREATE_INFO, STYPE_ALLOCATE_INFO))

"API structure types."
struct Structs <: Collection{SpecStruct}
  data::data_type(SpecStruct)
end

"""
Specification for a union type.
"""
struct SpecUnion <: Spec
  "Name of the union type."
  name::Symbol
  "Possible types for the union."
  types::Vector{ExprLike}
  "Fields which cast the struct into the union types"
  fields::Vector{Symbol}
  "Selector values, if any, to determine the type of the union in a given context (function call for example)."
  selectors::Vector{Symbol}
  """
  Whether the structure is only meant to be filled in by Vulkan functions, as opposed
  to being constructed by the user.

  Note that the API may still request the user to provide an initialized structure,
  notably as part of `pNext` chains for queries.
  """
  is_returnedonly::Bool
end

"API union types."
struct Unions <: Collection{SpecUnion}
  data::data_type(SpecUnion)
end
