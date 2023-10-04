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

"Describes what type of support an extension has per the specification."
@bitmask ExtensionSupport::UInt32 begin
  "Disabled."
  EXTENSION_SUPPORT_DISABLED = 0
  "Standard Vulkan."
  EXTENSION_SUPPORT_VULKAN = 1 << 0
  "Vulkan SC, for safety-critical systems."
  EXTENSION_SUPPORT_VULKAN_SC = 1 << 1
end

struct SpecExtension <: Spec
  name::String
  type::ExtensionType
  requirements::Vector{String}
  support::ExtensionSupport
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

iscore(spec, extensions::Extensions) = !haskey(extensions, spec)
function is_platform_specific(x, extensions::Extensions)
  extension = get(extensions, x, nothing)
  isnothing(extension) && return false
  extension.platform ≠ PLATFORM_NONE
end

"Return whether an extension is enabled for standard Vulkan - that is, a given symbol `x` is either core or is from an extension that has not been disabled, or is not exclusive to Vulkan SC."
isenabled(x, extensions::Extensions) = iscore(x, extensions) || EXTENSION_SUPPORT_VULKAN in extensions[x].support

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
