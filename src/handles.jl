"""
Specification for handle types.

A handle may possess a parent. In this case, the handle can only be valid if its parent is valid.

Some handles are dispatchable, which means that they are represented as opaque pointers.
Non-dispatchable handles are 64-bit integer types, and may encode information directly into their value.
"""
struct SpecHandle <: Spec
    "Name of the handle type."
    name::Symbol
    "Name of the parent handle, if any."
    parent::Optional{Symbol}
    "Whether the handle is dispatchable or not."
    is_dispatchable::Bool
end

"API handle types."
struct Handles <: Collection{SpecHandle}
  data::data_type(SpecHandle)
end

function parent_hierarchy(spec::SpecHandle, handles::Handles)
  isnothing(spec.parent) && return [spec.name]
  [parent_hierarchy(handles[spec.parent], handles); spec.name]
end

"""
Function `func` that creates a `handle` from a create info structure `create_info_struct` passed as the value of the parameter `create_info_param`.

If `batch` is true, then `func` expects a list of multiple create info structures and will create multiple handles at once.
"""
struct CreateFunc <: Spec
    func::SpecFunc
    handle::SpecHandle
    create_info_struct::Optional{SpecStruct}
    create_info_param::Optional{SpecFuncParam}
    batch::Bool
end

name(create::CreateFunc) = name(create.func)

function CreateFunc(spec::SpecFunc, handles::Handles, structs::Structs, aliases::Aliases)
  created_param = last(spec.params)
  handle = handles[follow_alias(innermost_type(created_param.type), aliases)]
  create_info_params = [spec.params[i] for i in findall(spec.params.type) do x
    type = get(structs, innermost_type(x), nothing)
    !isnothing(type) && iscreateinfo(type)
  end]
  @assert length(create_info_params) <= 1 "Found $(length(create_info_params)) create info types from the parameters of $spec:\n    $create_info_params"
  if length(create_info_params) == 0
    CreateFunc(spec, handle, nothing, nothing, false)
  else
    create_info_param = first(create_info_params)
    create_info_struct = structs[innermost_type(create_info_param.type)]
    batch = is_arr(created_param)
    CreateFunc(spec, handle, create_info_struct, create_info_param, batch)
  end
end

"API handle constructors."
struct Constructors <: Collection{CreateFunc}
  data::data_type(CreateFunc)
end

Constructors(functions::Functions, handles::Handles, structs::Structs, aliases::Aliases) = Constructors([CreateFunc(func, handles, structs, aliases) for func in functions[in.(functions.type, Ref((FTYPE_CREATE, FTYPE_ALLOCATE)))]])

"""
Function `func` that destroys a `handle` passed as the value of the parameter `destroyed_param`.

If `batch` is true, then `func` expects a list of multiple handles and will destroy all of them at once.
"""
struct DestroyFunc <: Spec
    func::SpecFunc
    handle::SpecHandle
    destroyed_param::SpecFuncParam
    batch::Bool
end

name(destroy::DestroyFunc) = name(destroy.func)

function DestroyFunc(spec::SpecFunc, handles::Handles)
  destroyed_param = find_destroyed_param(spec, handles)
  handle = handles[innermost_type(destroyed_param.type)]
  DestroyFunc(spec, handle, destroyed_param, is_arr(destroyed_param))
end

function find_destroyed_param(spec::SpecFunc, handles::Handles)
  idx = findlast(spec.params.is_externsync)
  @match idx begin
    ::Integer => spec.params[idx]
    ::Nothing => @match idx = findfirst(in(handles.name), innermost_type.(spec.params.type)) begin
      ::Integer => spec.params[idx + 1]
      ::Nothing => error("Failed to retrieve the parameter to be destroyed:\n $spec")
    end
  end
end

"API handle destructors."
struct Destructors <: Collection{DestroyFunc}
  data::data_type(DestroyFunc)
end

Destructors(functions::Functions, handles::Handles) = Destructors([DestroyFunc(func, handles) for func in functions[in.(functions.type, Ref((FTYPE_DESTROY, FTYPE_FREE)))]])

Base.getindex(funcs::Union{Constructors, Destructors}, handle::SpecHandle) = funcs[findall(x -> x.handle == handle, funcs)]
