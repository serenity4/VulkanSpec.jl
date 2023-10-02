var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = VulkanSpec","category":"page"},{"location":"#VulkanSpec","page":"Home","title":"VulkanSpec","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for VulkanSpec.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [VulkanSpec]","category":"page"},{"location":"#VulkanSpec.Authors","page":"Home","title":"VulkanSpec.Authors","text":"Specification authors.\n\nstruct Authors <: VulkanSpec.Collection{AuthorTag}\n\ndata::StructArrays.StructVector{AuthorTag, NamedTuple{(:tag, :author), Tuple{Vector{String}, Vector{String}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Bitmasks","page":"Home","title":"VulkanSpec.Bitmasks","text":"API bitmasks.\n\nstruct Bitmasks <: VulkanSpec.Collection{SpecBitmask}\n\ndata::StructArrays.StructVector{SpecBitmask, NamedTuple{(:name, :bits, :combinations, :width), Tuple{Vector{Symbol}, Vector{StructArrays.StructVector{SpecBit}}, Vector{StructArrays.StructVector{SpecBitCombination}}, Vector{Integer}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.CapabilitiesSPIRV","page":"Home","title":"VulkanSpec.CapabilitiesSPIRV","text":"SPIR-V capabilities.\n\nstruct CapabilitiesSPIRV <: VulkanSpec.Collection{SpecCapabilitySPIRV}\n\ndata::StructArrays.StructVector{SpecCapabilitySPIRV, NamedTuple{(:name, :promoted_to, :enabling_extensions, :enabling_features, :enabling_properties), Tuple{Vector{Symbol}, Vector{Union{Nothing, VersionNumber}}, Vector{Vector{String}}, Vector{Vector{FeatureCondition}}, Vector{Vector{PropertyCondition}}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Constants","page":"Home","title":"VulkanSpec.Constants","text":"API constants, usually defined in C with #define.\n\nstruct Constants <: VulkanSpec.Collection{SpecConstant}\n\ndata::StructArrays.StructVector{SpecConstant, NamedTuple{(:name, :value), Tuple{Vector{Symbol}, Vector{Any}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Constructors","page":"Home","title":"VulkanSpec.Constructors","text":"API handle constructors.\n\nstruct Constructors <: VulkanSpec.Collection{CreateFunc}\n\ndata::StructArrays.StructVector{CreateFunc, NamedTuple{(:func, :handle, :create_info_struct, :create_info_param, :batch), Tuple{Vector{SpecFunc}, Vector{SpecHandle}, Vector{Union{Nothing, SpecStruct}}, Vector{Union{Nothing, SpecFuncParam}}, Vector{Bool}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.CreateFunc","page":"Home","title":"VulkanSpec.CreateFunc","text":"Function func that creates a handle from a create info structure create_info_struct passed as the value of the parameter create_info_param.\n\nIf batch is true, then func expects a list of multiple create info structures and will create multiple handles at once.\n\nstruct CreateFunc <: Spec\n\nfunc::SpecFunc\nhandle::SpecHandle\ncreate_info_struct::Union{Nothing, SpecStruct}\ncreate_info_param::Union{Nothing, SpecFuncParam}\nbatch::Bool\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.DestroyFunc","page":"Home","title":"VulkanSpec.DestroyFunc","text":"Function func that destroys a handle passed as the value of the parameter destroyed_param.\n\nIf batch is true, then func expects a list of multiple handles and will destroy all of them at once.\n\nstruct DestroyFunc <: Spec\n\nfunc::SpecFunc\nhandle::SpecHandle\ndestroyed_param::SpecFuncParam\nbatch::Bool\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Destructors","page":"Home","title":"VulkanSpec.Destructors","text":"API handle destructors.\n\nstruct Destructors <: VulkanSpec.Collection{DestroyFunc}\n\ndata::StructArrays.StructVector{DestroyFunc, NamedTuple{(:func, :handle, :destroyed_param, :batch), Tuple{Vector{SpecFunc}, Vector{SpecHandle}, Vector{SpecFuncParam}, Vector{Bool}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Enums","page":"Home","title":"VulkanSpec.Enums","text":"API enumerated values, excluding bitmasks.\n\nstruct Enums <: VulkanSpec.Collection{SpecEnum}\n\ndata::StructArrays.StructVector{SpecEnum, NamedTuple{(:name, :enums), Tuple{Vector{Symbol}, Vector{StructArrays.StructVector{SpecConstant}}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Extensions","page":"Home","title":"VulkanSpec.Extensions","text":"API extensions.\n\nstruct Extensions <: VulkanSpec.Collection{SpecExtension}\n\ndata::StructArrays.StructVector{SpecExtension, NamedTuple{(:name, :type, :requirements, :is_disabled, :author, :symbols, :platform, :is_provisional, :promoted_to, :deprecated_by), Tuple{Vector{String}, Vector{VulkanSpec.ExtensionType}, Vector{Vector{String}}, Vector{Bool}, Vector{Union{Nothing, String}}, Vector{Vector{Symbol}}, Vector{PlatformType}, Vector{Bool}, Vector{Union{Nothing, VersionNumber, String}}, Vector{Union{Nothing, String}}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.ExtensionsSPIRV","page":"Home","title":"VulkanSpec.ExtensionsSPIRV","text":"SPIR-V extensions.\n\nstruct ExtensionsSPIRV <: VulkanSpec.Collection{SpecExtensionSPIRV}\n\ndata::StructArrays.StructVector{SpecExtensionSPIRV, NamedTuple{(:name, :promoted_to, :enabling_extensions), Tuple{Vector{String}, Vector{Union{Nothing, VersionNumber}}, Vector{Vector{String}}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.FieldIterator","page":"Home","title":"VulkanSpec.FieldIterator","text":"Iterate through function or struct specification fields from a list of fields. list is a sequence of fields to get through from root.\n\nstruct FieldIterator\n\nroot::Union{SpecFuncParam, SpecStructMember}\nlist::Vector{Symbol}\nstructs::Structs\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Flags","page":"Home","title":"VulkanSpec.Flags","text":"API flags.\n\nstruct Flags <: VulkanSpec.Collection{SpecFlag}\n\ndata::StructArrays.StructVector{SpecFlag, NamedTuple{(:name, :typealias, :bitmask), Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Union{Nothing, SpecBitmask}}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.FunctionType","page":"Home","title":"VulkanSpec.FunctionType","text":"Function type classification.\n\nTypes:\n\nFTYPE_CREATE: constructor (functions that begin with vkCreate).\nFTYPE_DESTROY: destructor (functions that begin with vkDestroy).\nFTYPE_ALLOCATE: allocator (functions that begin with vkAllocate).\nFTYPE_FREE: deallocator (functions that begin with vkFree).\nFTYPE_COMMAND: Vulkan command (functions that begin with vkCmd).\nFTYPE_QUERY: used to query parameters, returned directly or indirectly through pointer mutation (typically, functions that begin with vkEnumerate and vkGet, but not all of them and possibly others).\nFTYPE_OTHER: no identified type.\n\nprimitive type FunctionType <: Enum{Int32} 32\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Functions","page":"Home","title":"VulkanSpec.Functions","text":"API functions.\n\nstruct Functions <: VulkanSpec.Collection{SpecFunc}\n\ndata::StructArrays.StructVector{SpecFunc, NamedTuple{(:name, :type, :return_type, :render_pass_compatibility, :queue_compatibility, :params, :success_codes, :error_codes), Tuple{Vector{Symbol}, Vector{FunctionType}, Vector{Union{Nothing, Expr, Symbol}}, Vector{Vector{RenderPassRequirement}}, Vector{Vector{QueueType}}, Vector{StructArrays.StructVector{SpecFuncParam}}, Vector{Vector{Symbol}}, Vector{Vector{Symbol}}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Handles","page":"Home","title":"VulkanSpec.Handles","text":"API handle types.\n\nstruct Handles <: VulkanSpec.Collection{SpecHandle}\n\ndata::StructArrays.StructVector{SpecHandle, NamedTuple{(:name, :parent, :is_dispatchable), Tuple{Vector{Symbol}, Vector{Union{Nothing, Symbol}}, Vector{Bool}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.PARAM_REQUIREMENT","page":"Home","title":"VulkanSpec.PARAM_REQUIREMENT","text":"Parameter requirement. Applies both to struct members and function parameters.\n\nRequirement types: \n\nOPTIONAL: may have its default zero (or nullptr) value, acting as a sentinel value (similar to Nothing in Julia).\nREQUIRED: must be provided, no sentinel value is allowed.\nPOINTER_OPTIONAL: is a pointer which may be null, but must have valid elements if provided.\nPOINTER_REQUIRED: must be a valid pointer, but its elements are optional (e.g. are allowed to be sentinel values).\n\nprimitive type PARAM_REQUIREMENT <: Enum{Int32} 32\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.QueueType","page":"Home","title":"VulkanSpec.QueueType","text":"Queue type on which a computation can be carried.\n\nabstract type QueueType\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.RenderPassOutside","page":"Home","title":"VulkanSpec.RenderPassOutside","text":"The command can be executed outside a render pass.\n\nstruct RenderPassOutside <: RenderPassRequirement\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.RenderPassRequirement","page":"Home","title":"VulkanSpec.RenderPassRequirement","text":"Render pass execution specification for commands.\n\nabstract type RenderPassRequirement\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Spec","page":"Home","title":"VulkanSpec.Spec","text":"Everything that a Vulkan specification can apply to: data structures, functions, parameters...\n\nabstract type Spec\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecAlias","page":"Home","title":"VulkanSpec.SpecAlias","text":"Specification for an alias of the form const <name> = <alias>.\n\nstruct SpecAlias{S<:Spec} <: Spec\n\nname::Symbol: Name of the new alias.\nalias::Spec: Aliased specification element.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecBit","page":"Home","title":"VulkanSpec.SpecBit","text":"Specification for a bit used in a bitmask.\n\nstruct SpecBit <: Spec\n\nname::Symbol: Name of the bit.\nposition::Int64: Position of the bit.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecBitmask","page":"Home","title":"VulkanSpec.SpecBitmask","text":"Specification for a bitmask type that must be formed through a combination of bits.\n\nIs usually an alias for a UInt32 type which carries meaning through its bits.\n\nstruct SpecBitmask <: Spec\n\nname::Symbol: Name of the bitmask type.\nbits::StructArrays.StructVector{SpecBit}: Valid bits that can be combined to form the final bitmask value.\ncombinations::StructArrays.StructVector{SpecBitCombination}\nwidth::Integer\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecConstant","page":"Home","title":"VulkanSpec.SpecConstant","text":"Specification for a constant.\n\nstruct SpecConstant <: Spec\n\nname::Symbol: Name of the constant.\nvalue::Any: Value of the constant.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecEnum","page":"Home","title":"VulkanSpec.SpecEnum","text":"Specification for an enumeration type.\n\nstruct SpecEnum <: Spec\n\nname::Symbol: Name of the enumeration type.\nenums::StructArrays.StructVector{SpecConstant}: Vector of possible enumeration values.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecFlag","page":"Home","title":"VulkanSpec.SpecFlag","text":"Specification for a flag type name that is a type alias of typealias. Can be associated with a bitmask structure, in which case the bitmask number is set to the corresponding SpecBitmask.\n\nstruct SpecFlag <: Spec\n\nname::Symbol: Name of the flag type.\ntypealias::Symbol: The type it aliases.\nbitmask::Union{Nothing, SpecBitmask}: Bitmask, if applicable.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecFunc","page":"Home","title":"VulkanSpec.SpecFunc","text":"Specification for a function.\n\nstruct SpecFunc <: Spec\n\nname::Symbol: Name of the function.\ntype::FunctionType: FunctionType classification.\nreturn_type::Union{Nothing, Expr, Symbol}: Return type (void if Nothing).\nrender_pass_compatibility::Vector{RenderPassRequirement}: Whether the function can be executed inside a render pass, outside, or both. Empty if not specified, in which case it is equivalent to both inside and outside.\nqueue_compatibility::Vector{QueueType}: Type of queues on which the function can be executed. Empty if not specified, in which case it is equivalent to being executable on all queues.\nparams::StructArrays.StructVector{SpecFuncParam}: Function parameters.\nsuccess_codes::Vector{Symbol}\nerror_codes::Vector{Symbol}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecFuncParam","page":"Home","title":"VulkanSpec.SpecFuncParam","text":"Specification for a function parameter.\n\nstruct SpecFuncParam <: Spec\n\nfunc::Symbol: Name of the parent function.\nname::Symbol: Identifier.\ntype::Union{Expr, Symbol}: Expression of its idiomatic Julia type.\nis_constant::Bool: If constant, cannot be mutated by Vulkan functions.\nis_externsync::Bool: Whether it must be externally synchronized before calling the function.\nrequirement::PARAM_REQUIREMENT: PARAM_REQUIREMENT classification.\nlen::Union{Nothing, Symbol}: Name of the parameter (of the same function) which represents its length. Nothing for non-vector types.\narglen::Vector{Symbol}: Name of the parameters (of the same function) it is a length of.\nautovalidity::Bool: Whether automatic validity documentation is enabled. If false, this means that the parameter may be an exception to at least one Vulkan convention.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecHandle","page":"Home","title":"VulkanSpec.SpecHandle","text":"Specification for handle types.\n\nA handle may possess a parent. In this case, the handle can only be valid if its parent is valid.\n\nSome handles are dispatchable, which means that they are represented as opaque pointers. Non-dispatchable handles are 64-bit integer types, and may encode information directly into their value.\n\nstruct SpecHandle <: Spec\n\nname::Symbol: Name of the handle type.\nparent::Union{Nothing, Symbol}: Name of the parent handle, if any.\nis_dispatchable::Bool: Whether the handle is dispatchable or not.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecPlatform","page":"Home","title":"VulkanSpec.SpecPlatform","text":"API platforms.\n\nstruct SpecPlatform <: Spec\n\ntype::PlatformType\ndescription::String\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecStruct","page":"Home","title":"VulkanSpec.SpecStruct","text":"Specification for a structure.\n\nstruct SpecStruct <: Spec\n\nname::Symbol: Name of the structure.\ntype::StructType: StructType classification.\nis_returnedonly::Bool: Whether the structure is only meant to be filled in by Vulkan functions, as opposed to being constructed by the user.\nNote that the API may still request the user to provide an initialized structure, notably as part of pNext chains for queries.\n\nextends::Vector{Symbol}: Name of the structures it extends, usually done through the original structures' pNext argument.\nmembers::StructArrays.StructVector{SpecStructMember}: Structure members.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecStructMember","page":"Home","title":"VulkanSpec.SpecStructMember","text":"Specification for a structure parameter.\n\nstruct SpecStructMember <: Spec\n\nparent::Symbol: Name of the parent structure.\nname::Symbol: Identifier.\ntype::Union{Expr, Symbol}: Expression of its idiomatic Julia type.\nis_constant::Bool: If constant, cannot be mutated by Vulkan functions.\nis_externsync::Bool: Whether it must be externally synchronized before calling any function which uses the parent structure.\nrequirement::PARAM_REQUIREMENT: PARAM_REQUIREMENT classification.\nlen::Union{Nothing, Expr, Symbol}: Name of the member (of the same structure) which represents its length. Nothing for non-vector types.\narglen::Vector{Union{Expr, Symbol}}: Name of the members (of the same structure) it is a length of.\nautovalidity::Bool: Whether automatic validity documentation is enabled. If false, this means that the member may be an exception to at least one Vulkan convention.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.SpecUnion","page":"Home","title":"VulkanSpec.SpecUnion","text":"Specification for a union type.\n\nstruct SpecUnion <: Spec\n\nname::Symbol: Name of the union type.\ntypes::Vector{Union{Expr, Symbol}}: Possible types for the union.\nfields::Vector{Symbol}: Fields which cast the struct into the union types\nselectors::Vector{Symbol}: Selector values, if any, to determine the type of the union in a given context (function call for example).\nis_returnedonly::Bool: Whether the structure is only meant to be filled in by Vulkan functions, as opposed to being constructed by the user.\nNote that the API may still request the user to provide an initialized structure, notably as part of pNext chains for queries.\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.StructType","page":"Home","title":"VulkanSpec.StructType","text":"Structure type classification.\n\nTypes:\n\nSTYPE_CREATE_INFO: holds constructor parameters (structures that end with CreateInfo).\nSTYPE_ALLOCATE_INFO: holds allocator parameters (structures that end with AllocateInfo).\nSTYPE_GENERIC_INFO: holds parameters for another function or structure (structures that end with Info, excluding those falling into the previous types).\nSTYPE_DATA: usually represents user or Vulkan data.\nSTYPE_PROPERTY: is a property returned by Vulkan in a returnedonly structure, usually done through FTYPE_QUERY type functions.\n\nprimitive type StructType <: Enum{Int32} 32\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Structs","page":"Home","title":"VulkanSpec.Structs","text":"API structure types.\n\nstruct Structs <: VulkanSpec.Collection{SpecStruct}\n\ndata::StructArrays.StructVector{SpecStruct, NamedTuple{(:name, :type, :is_returnedonly, :extends, :members), Tuple{Vector{Symbol}, Vector{StructType}, Vector{Bool}, Vector{Vector{Symbol}}, Vector{StructArrays.StructVector{SpecStructMember}}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.Unions","page":"Home","title":"VulkanSpec.Unions","text":"API union types.\n\nstruct Unions <: VulkanSpec.Collection{SpecUnion}\n\ndata::StructArrays.StructVector{SpecUnion, NamedTuple{(:name, :types, :fields, :selectors, :is_returnedonly), Tuple{Vector{Symbol}, Vector{Vector{Union{Expr, Symbol}}}, Vector{Vector{Symbol}}, Vector{Vector{Symbol}}, Vector{Bool}}}, Int64}\n\n\n\n\n\n","category":"type"},{"location":"#VulkanSpec.hasalias-Tuple{Any, VulkanSpec.Aliases}","page":"Home","title":"VulkanSpec.hasalias","text":"Whether an alias was built from this name.\n\nhasalias(\n    name,\n    aliases::VulkanSpec.Aliases\n) -> Union{Missing, Bool}\n\n\n\n\n\n\n","category":"method"},{"location":"#VulkanSpec.is_inferable_length-Tuple{Spec}","page":"Home","title":"VulkanSpec.is_inferable_length","text":"True if the argument that can be inferred from other arguments.\n\nis_inferable_length(spec::Spec) -> Bool\n\n\n\n\n\n\n","category":"method"},{"location":"#VulkanSpec.is_length_exception-Tuple{Spec}","page":"Home","title":"VulkanSpec.is_length_exception","text":"True if the argument behaves differently than other length parameters.\n\nis_length_exception(spec::Spec) -> Bool\n\n\n\n\n\n\n","category":"method"},{"location":"#VulkanSpec.isalias-Tuple{Any, VulkanSpec.Aliases}","page":"Home","title":"VulkanSpec.isalias","text":"Whether this type is an alias for another name.\n\nisalias(name, aliases::VulkanSpec.Aliases) -> Bool\n\n\n\n\n\n\n","category":"method"},{"location":"#VulkanSpec.translate_c_type-Tuple{Any}","page":"Home","title":"VulkanSpec.translate_c_type","text":"Semantically translate C types to their Julia counterpart. Note that since it is a semantic translation, translated types do not necessarily have the same layout, e.g. VkBool32 => Bool (8 bits).\n\ntranslate_c_type(ctype) -> Any\n\n\n\n\n\n\n","category":"method"}]
}
