module VulkanSpec

using StructArrays: StructVector
using Graphs
using MLStyle
using DocStringExtensions
using EzXML: Document, Node, readxml
using ForwardMethods
using Vulkan_Headers_jll: vk_xml
using InteractiveUtils: subtypes
using BitMasks: @bitmask
using Dictionaries
using Accessors: @set, setproperties
using PrecompileTools

@template (FUNCTIONS, METHODS, MACROS) = """
                                         $(DOCSTRING)
                                         $(TYPEDSIGNATURES)
                                         """

@template TYPES = """
                  $(DOCSTRING)
                  $(TYPEDEF)
                  $(TYPEDSIGNATURES)
                  $(TYPEDFIELDS)
                  $(SIGNATURES)
                  """

const ExprLike = Union{Symbol,Expr}
const Optional{T} = Union{Nothing,T}

const extension_types = [
  :Display,
  :VisualID,
  :Window,
  :RROutput,
  :wl_display,
  :wl_surface,
  :HINSTANCE,
  :HWND,
  :HMONITOR,
  :HANDLE,
  :SECURITY_ATTRIBUTES,
  :DWORD,
  :LPCWSTR,
  :xcb_connection_t,
  :xcb_visualid_t,
  :xcb_window_t,
  :IDirectFB,
  :IDirectFBSurface,
  :zx_handle_t,
  :GgpStreamDescriptor,
  :GgpFrameToken,
  :MirConnection,
  :MirSurface,
  :ANativeWindow,
  :AHardwareBuffer,
  :CAMetalLayer,
  :_screen_context,
  :_screen_window,
]

"""
Everything that a Vulkan specification can apply to: data structures, functions, parameters...
"""
abstract type Spec end

Base.broadcastable(spec::Spec) = Ref(spec)
Base.:(==)(x::S, y::S) where {S<:Spec} = all(name -> getproperty(x, name) == getproperty(y, name), fieldnames(S))

include("utils.jl")
include("collection.jl")
include("aliases.jl")
include("features.jl")
include("constants.jl")
include("types.jl")
include("functions.jl")
include("handles.jl")
include("parse.jl")
include("api.jl")
include("diff.jl")
include("show.jl")

for T in subtypes(Collection)
  S = eltype(supertype(T))
  T, S = nameof(T), nameof(S)
  @eval $T(data::Vector{$S}) = $T(StructVector(data))
  @eval function $T(xml::Document, args...)
    data = [$S(node, args...) for node in nodes($S, xml)]
    $T(data)
  end
  @eval export $T
end

for sym in names(@__MODULE__, all = true)
  if any(startswith(string(sym), prefix) for prefix in ["PLATFORM_", "FTYPE_", "STYPE_", "EXTENSION_", "SYMBOL_", "Spec", "Queue", "RenderPass"])
    @eval export $sym
  end
end

@compile_workload begin
  api = VulkanAPI(joinpath(pkgdir(@__MODULE__), "specs", "vk.1.3.207.xml"))
  for collection in (api.extensions, api.functions, api.structs, api.authors, api)
    sprint(show, collection)
    sprintcm(show, collection)
  end
  sprintcm(show, api.extensions[2])
  sprintcm(show, api.sets[4])
  sprintcm(show, api.sets[end])
end

export
  # Types
  Spec,
  SpecAlias,
  SpecBit,
  SpecBitCombination,
  SpecBitmask,
  SpecConstant,
  SpecEnum,
  SpecExtension, iscore, isenabled,
  SpecFlag,
  SpecFunc,
  SpecFuncParam,
  SpecStruct,
  SpecStructMember,
  SpecHandle,
  SpecUnion,
  SpecExtensionSPIRV,
  FeatureCondition, PropertyCondition, SpecCapabilitySPIRV,
  CreateFunc,
  DestroyFunc,
  AuthorTag,
  PlatformType,

  # Classification
  extension_types,

  # API
  VulkanAPI,
  Diff, RemovedSymbol, isbreaking,
  SymbolType, SymbolInfo,
  SymbolGroup, defined_symbols,
  ApplicableAPI, VULKAN, VULKAN_SC,
  filter_applicable_symbols,

  # Alias manipulation
  alias_dict,
  follow_alias,
  isalias,
  hasalias,

  # Specifications
  ### Utility
  follow_constant,
  children,
  parent_hierarchy,
  len,
  arglen,
  is_length,
  is_length_exception,
  is_inferable_length,
  length_chain,
  is_arr,
  is_tuple_arr,
  is_size,
  is_data,
  is_version,

  ### Render passes
  render_pass_compatibility_map,

  ### Structures & functions
  PARAM_REQUIREMENT,
  OPTIONAL,
  REQUIRED,
  POINTER_OPTIONAL,
  POINTER_REQUIRED,
  StructType,
  FunctionType

end # module
