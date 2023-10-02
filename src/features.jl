@enum ExtensionType begin
  EXTENSION_TYPE_INSTANCE
  EXTENSION_TYPE_DEVICE
  EXTENSION_TYPE_ANY
end

@bitmask PlatformType::UInt32 begin
  PLATFORM_NONE        = 0
  PLATFORM_XCB         = 1
  PLATFORM_XLIB        = 2
  PLATFORM_XLIB_XRANDR = 4
  PLATFORM_WAYLAND     = 8
  PLATFORM_METAL       = 16
  PLATFORM_MACOS       = 32
  PLATFORM_IOS         = 64
  PLATFORM_WIN32       = 128
  PLATFORM_ANDROID     = 256
  PLATFORM_GGP         = 512
  PLATFORM_VI          = 1024
  PLATFORM_FUCHSIA     = 2048
  PLATFORM_DIRECTFB    = 4096
  PLATFORM_SCREEN      = 8192
  PLATFORM_PROVISIONAL = 16384
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
  is_disabled::Bool
  author::Optional{String}
  symbols::Vector{Symbol}
  platform::PlatformType
  is_provisional::Bool
  "Core version or core extension which this extension was promoted to, if promoted."
  promoted_to::Optional{Union{VersionNumber,String}}
  deprecated_by::Optional{String}
end

matches(name::Symbol, x::SpecExtension) = name == x.name || name in x.symbols

"API extensions."
struct Extensions <: Collection{SpecExtension}
  data::data_type(SpecExtension)
end

Extensions(xml::Document) = Extensions(SpecExtension.(findall("//extension", xml)))

is_core(spec, extensions::Extensions) = !haskey(extensions, spec)
function is_platform_specific(x, extensions::Extensions)
  extension = get(extensions, x, nothing)
  isnothing(extension) && return false
  extension.platform ≠ PLATFORM_NONE
end

isenabled(x, extensions::Extensions) = is_core(x, extensions) || !(extensions[x].is_disabled)

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
