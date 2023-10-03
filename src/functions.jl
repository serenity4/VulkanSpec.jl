"""
Queue type on which a computation can be carried.
"""
abstract type QueueType end

struct QueueCompute <: QueueType end
struct QueueGraphics <: QueueType end
struct QueueTransfer <: QueueType end
struct QueueSparseBinding <: QueueType end
struct QueueVideoDecode <: QueueType end
struct QueueVideoEncode <: QueueType end

"""
Render pass execution specification for commands.
"""
abstract type RenderPassRequirement end

"""
The command can be executed inside a render pass.
"""

struct RenderPassInside <: RenderPassRequirement end

"""
The command can be executed outside a render pass.
"""
struct RenderPassOutside <: RenderPassRequirement end

"""
Function type classification.

Types:
- `FTYPE_CREATE`: constructor (functions that begin with `vkCreate`).
- `FTYPE_DESTROY`: destructor (functions that begin with `vkDestroy`).
- `FTYPE_ALLOCATE`: allocator (functions that begin with `vkAllocate`).
- `FTYPE_FREE`: deallocator (functions that begin with `vkFree`).
- `FTYPE_COMMAND`: Vulkan command (functions that begin with `vkCmd`).
- `FTYPE_QUERY`: used to query parameters, returned directly or indirectly through pointer mutation (typically, functions that begin with `vkEnumerate` and `vkGet`, but not all of them and possibly others).
- `FTYPE_OTHER`: no identified type.
"""
@enum FunctionType FTYPE_CREATE FTYPE_DESTROY FTYPE_ALLOCATE FTYPE_FREE FTYPE_COMMAND FTYPE_QUERY FTYPE_OTHER

"""
Specification for a function parameter.
"""
struct SpecFuncParam <: Spec
  "Name of the parent function."
  parent::Any
  "Identifier."
  name::Symbol
  "Expression of its idiomatic Julia type."
  type::ExprLike
  "If constant, cannot be mutated by Vulkan functions."
  is_constant::Bool
  "Whether it must be externally synchronized before calling the function."
  is_externsync::Bool
  "[`PARAM_REQUIREMENT`](@ref) classification."
  requirement::PARAM_REQUIREMENT
  "Name of the parameter (of the same function) which represents its length. `Nothing` for non-vector types."
  len::Optional{Symbol}
  "Name of the parameters (of the same function) it is a length of."
  arglen::Vector{Symbol}
  "Whether automatic validity documentation is enabled. If false, this means that the parameter may be an exception to at least one Vulkan convention."
  autovalidity::Bool
end

function Base.getproperty(param::SpecFuncParam, name::Symbol)
  name === :parent && return getfield(param, :parent)::SpecFunc
  getfield(param, name)
end

Base.:(==)(x::SpecFuncParam, y::SpecFuncParam) = all(getproperty(x, name) == getproperty(y, name) for name in fieldnames(SpecFuncParam) if name !== :parent)

"""
Iterate through function or struct specification fields from a list of fields.
`list` is a sequence of fields to get through from `root`.
"""
struct FieldIterator
  root::Union{SpecFuncParam, SpecStructMember}
  list::Vector{Symbol}
  structs::Structs
end

function Base.iterate(f::FieldIterator, state = (0, f.root))
  (i, root) = state
  if i == 0
    spec = f.root
  else
    type = innermost_type(root.type)
    s = get(f.structs, type, nothing)
    if isnothing(s)
      i > lastindex(f.list) || error("Failed to retrieve a struct from $root to continue the list $(f.list)")
      return nothing
    else
      spec = s[f.list[i]]
    end
  end
  state = i + 1 > lastindex(f.list) ? nothing : (i + 1, spec)
  (spec, state)
end

Base.iterate(f::FieldIterator, ::Nothing) = nothing
Base.length(f::FieldIterator) = 1 + length(f.list)

"""
Specification for a function.
"""
struct SpecFunc <: Spec
  "Name of the function."
  name::Symbol
  "[`FunctionType`](@ref) classification."
  type::FunctionType
  "Return type (void if `Nothing`)."
  return_type::Optional{ExprLike}
  "Whether the function can be executed inside a render pass, outside, or both. Empty if not specified, in which case it is equivalent to both inside and outside."
  render_pass_compatibility::Vector{RenderPassRequirement}
  "Type of queues on which the function can be executed. Empty if not specified, in which case it is equivalent to being executable on all queues."
  queue_compatibility::Vector{QueueType}
  "Function parameters."
  params::StructVector{SpecFuncParam}
  success_codes::Vector{Symbol}
  error_codes::Vector{Symbol}
  function SpecFunc(name, type, return_type, render_pass_compatibility, queue_compatibility, params, success_codes, error_codes)
    func = new(name, type, return_type, render_pass_compatibility, queue_compatibility, StructVector(SpecFuncParam[]), success_codes, error_codes)
    for param in params
      push!(func.params, isa(param, SpecFuncParam) ? param : SpecFuncParam(param, func))
    end
    func
  end
end

@forward_methods SpecFunc field = :params Base.keys
@forward_interface SpecFunc field = :params interface = [iteration, indexing]
function Base.getindex(func::SpecFunc, _name::Symbol)
  i = findfirst(==(_name) ∘ name, func.params)
  isnothing(i) ? throw(KeyError(_name)) : func.params[i]
end
children(spec::SpecFunc) = spec.params

"API functions."
struct Functions <: Collection{SpecFunc}
  data::data_type(SpecFunc)
end

is_arr(spec::Union{SpecStructMember,SpecFuncParam}) = !isnothing(spec.len) && innermost_type(spec.type) ≠ :Cvoid
is_length(spec::Union{SpecStructMember,SpecFuncParam}) = !isempty(spec.arglen) && !is_size(spec)
is_size(spec::Union{SpecStructMember,SpecFuncParam}) = !isempty(spec.arglen) && endswith(string(spec.name), r"[sS]ize")
is_data(spec::Union{SpecStructMember,SpecFuncParam}) = !isnothing(spec.len) && spec.type == :(Ptr{Cvoid})
is_version(spec::Union{SpecStructMember,SpecFuncParam}, constants::Constants) =
  !isnothing(match(r"($v|V)ersion", string(spec.name))) && (
    follow_constant(spec.type, constants) == :UInt32 ||
    is_ptr(spec.type) && !is_arr(spec) && !spec.is_constant && follow_constant(ptr_type(spec.type), constants) == :UInt32
  )

"""
    len(pCode)

Return the function parameter or struct member which describes the length of the provided pointer argument.
When the length is more complex than a simple argument, i.e. is a function of another parameter, `missing` is returned.
In this case, refer to the `.len` field of the argument to get the correct `Expr`.
"""
function len end

len(spec::Union{SpecFunc, SpecStruct}, arg::ExprLike) = missing
len(spec::Union{SpecFunc, SpecStruct}, arg::Symbol) = spec[findfirst(==(arg) ∘ name, spec)::Int]
len(spec::SpecStructMember) = len(spec.parent, spec.len)
len(spec::SpecFuncParam) = len(spec.parent, spec.len)

"""
    arglen(queueCount)

Return the function parameters or struct members whose length is encoded by the provided argument.
"""
function arglen end
arglen(spec::Union{SpecFunc, SpecStruct}, names::Vector{<:ExprLike}) = spec[findall(in(names) ∘ name, spec)]
arglen(spec::SpecStructMember) = arglen(spec.parent, spec.arglen)
arglen(spec::SpecFuncParam) = arglen(spec.parent, spec.arglen)

"""
True if the argument behaves differently than other length parameters, and requires special care.
"""
function is_length_exception(spec::SpecStructMember)
  is_length(spec) && @match spec.parent.name begin
    # see `descriptorCount` at https://www.khronos.org/registry/vulkan/specs/1.1-extensions/html/vkspec.html#VkWriteDescriptorSet
    :VkWriteDescriptorSet => spec.name == :descriptorCount
    _ => false
  end
end
is_length_exception(spec::SpecFuncParam) = false

"""
True if the argument that can be inferred from other arguments.
"""
function is_inferable_length(spec::SpecStructMember)
  is_length(spec) && @match spec.parent.name begin
    :VkDescriptorSetLayoutBinding => spec.name ≠ :descriptorCount
    _ => true
  end
end
is_inferable_length(spec::SpecFuncParam) = true

function length_chain(spec::Union{SpecStructMember, SpecFuncParam}, chain, structs)
  parts = Symbol.(split(string(chain), "->"))
  collect(FieldIterator(spec, @view(parts[2:end]), structs))
end
