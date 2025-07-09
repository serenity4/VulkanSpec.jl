"Describes which type of Vulkan API the specification applies to."
@enum ApplicableAPI VULKAN VULKAN_SC
@doc "Standard Vulkan." VULKAN
@doc "Vulkan SC, for safety-critical systems." VULKAN_SC

@enum SymbolType SYMBOL_ENUM = 1 SYMBOL_TYPE = 2 SYMBOL_COMMAND = 3

function SymbolType(node::Node)
  name = Symbol(node.name)
  name === :enum && return SYMBOL_ENUM
  name === :type && return SYMBOL_TYPE
  name === :command && return SYMBOL_COMMAND
  error("Unknown symbol type '$name'")
end

struct SymbolInfo
  name::Symbol
  type::SymbolType
  deprecated::Bool
end

struct SymbolGroup
  applicable::Vector{ApplicableAPI}
  symbols::Vector{SymbolInfo}
  depends_on::Vector{String}
  description::Optional{String}
end

Base.contains(group::SymbolGroup, symbol::Symbol) = any(x -> x.name === symbol, group.symbols)
Base.in(symbol::Symbol, group::SymbolGroup) = contains(group, symbol)

parse_applicable_apis(node::Node) = parse_applicable_apis(split(getattr(node, "api"; default = "", symbol = false)))

function parse_applicable_apis(list::AbstractVector)
  applicable = ApplicableAPI[]
  in("vulkan", list) && push!(applicable, VULKAN)
  in("vulkansc", list) && push!(applicable, VULKAN_SC)
  return applicable
end

function SymbolGroup(node::Node)
  applicable = parse_applicable_apis(node)
  symbols = SymbolInfo[]
  for child in findall("./*[self::enum or self::type or self::command]", node)
    name = getattr(child, "name")
    type = SymbolType(child)
    deprecated = haskey(child, "deprecated") && in(child["deprecated"], ("true", "aliased"))
    push!(symbols, SymbolInfo(name, type, deprecated))
  end
  depends_on = split(getattr(node, "depends_on"; default = "", symbol = false), ',')
  description = getattr(node, "comment"; default = nothing, symbol = false)
  SymbolGroup(applicable, symbols, depends_on, description)
end

defined_symbols(group::SymbolGroup) = map(x -> x.name, group.symbols)

@enum ExtensionType begin
  EXTENSION_TYPE_INSTANCE
  EXTENSION_TYPE_DEVICE
  EXTENSION_TYPE_ANY
end

@bitmask PlatformType::UInt32 begin
  PLATFORM_NONE        = 0
  PLATFORM_XCB         = 1 << 0
  PLATFORM_XLIB        = 1 << 1
  PLATFORM_XLIB_XRANDR = 1 << 2
  PLATFORM_WAYLAND     = 1 << 3
  PLATFORM_METAL       = 1 << 4
  PLATFORM_MACOS       = 1 << 5
  PLATFORM_IOS         = 1 << 6
  PLATFORM_WIN32       = 1 << 7
  PLATFORM_ANDROID     = 1 << 8
  PLATFORM_GGP         = 1 << 9
  PLATFORM_VI          = 1 << 10
  PLATFORM_FUCHSIA     = 1 << 11
  PLATFORM_DIRECTFB    = 1 << 12
  PLATFORM_SCREEN      = 1 << 13
  PLATFORM_PROVISIONAL = 1 << 14
  PLATFORM_SCI         = 1 << 15
end

"API platforms."
struct SpecPlatform <: Spec
  type::PlatformType
  description::String
end

key(spec::SpecPlatform) = spec.type

struct Platforms <: Collection{SpecPlatform}
  data::data_type(SpecPlatform)
end

struct SpecExtension <: Spec
  name::String
  type::ExtensionType
  requirements::Vector{String}
  applicable::Vector{ApplicableAPI}
  author::Optional{String}
  groups::Vector{SymbolGroup}
  platform::PlatformType
  is_provisional::Bool
  disabled::Bool
  "Core version or core extension which this extension was promoted to, if promoted."
  promoted_to::Optional{Union{VersionNumber,String}}
  deprecated_by::Optional{String}
end

Base.contains(extension::SpecExtension, symbol::Symbol) = any(contains(symbol), extension.groups)
Base.in(symbol::Symbol, extension::SpecExtension) = contains(extension, symbol)
defined_symbols(extension::SpecExtension) = foldl((x, y) -> append!(x, defined_symbols(y)), extension.groups; init = Symbol[])

matches(name::Symbol, x::SpecExtension) = name == x.name || contains(x, name)

"API extensions."
struct Extensions <: Collection{SpecExtension}
  data::data_type(SpecExtension)
end

Extensions(xml::Document) = Extensions(SpecExtension.(findall("//extension", xml)))

iscore(spec, extensions::Extensions) = !haskey(extensions, spec)
function is_platform_specific(x, extensions::Extensions)
  extension = get(extensions, x, nothing)
  isnothing(extension) && return false
  extension.platform ≠ PLATFORM_NONE
end

"Return whether an extension is enabled for standard Vulkan - that is, a given symbol `x` is either core or is from an extension that has not been disabled, or is not exclusive to Vulkan SC."
function isenabled(x, extensions::Extensions)
  iscore(x, extensions) && return true
  extension = extensions[x]
  !extension.disabled && in(VULKAN, extension.applicable)
end

struct AuthorTag <: Spec
  tag::String
  author::String
end

"Specification authors."
struct Authors <: Collection{AuthorTag}
  data::data_type(AuthorTag)
end

key(tag::AuthorTag) = tag.tag

struct SpecExtensionSPIRV <: Spec
  "Name of the SPIR-V extension."
  name::String
  "Core version of the Vulkan API in which the extension was promoted, if promoted."
  promoted_to::Optional{VersionNumber}
  "Vulkan extensions that implicitly enable the SPIR-V extension."
  enabling_extensions::Vector{String}
end

"SPIR-V extensions."
struct ExtensionsSPIRV <: Collection{SpecExtensionSPIRV}
  data::data_type(SpecExtensionSPIRV)
end

struct FeatureCondition
  "Name of the feature structure relevant to the condition."
  type::Symbol
  "Member of the structure which must be set to true to enable the feature."
  member::Symbol
  "Core version corresponding to the structure, if any."
  core_version::Optional{VersionNumber}
  "Extension required for the corresponding structure, if any."
  extension::Optional{String}
end

struct PropertyCondition
  "Name of the property structure relevant to the condition."
  type::Symbol
  "Member of the property structure to be tested."
  member::Symbol
  "Required core version of the Vulkan API, if any."
  core_version::Optional{VersionNumber}
  "Required extension, if any."
  extension::Optional{String}
  "Whether the property to test is a boolean. If not, then it will be a bit from a bitmask."
  is_bool::Bool
  "Name of the bit enum that must be included in the property, if the property is not a boolean."
  bit::Optional{Symbol}
end

struct SpecCapabilitySPIRV <: Spec
  "Name of the SPIR-V capability."
  name::Symbol
  "Core version of the Vulkan API in which the extension was promoted, if promoted."
  promoted_to::Optional{VersionNumber}
  "Vulkan extensions that implicitly enable the SPIR-V capability."
  enabling_extensions::Vector{String}
  "Vulkan features that implicitly enable the SPIR-V capability."
  enabling_features::Vector{FeatureCondition}
  "Vulkan properties that implicitly enable the SPIR-V capability."
  enabling_properties::Vector{PropertyCondition}
end

"SPIR-V capabilities."
struct CapabilitiesSPIRV <: Collection{SpecCapabilitySPIRV}
  data::data_type(SpecCapabilitySPIRV)
end
