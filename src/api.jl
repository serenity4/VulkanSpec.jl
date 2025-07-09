@enum VulkanAPISubset VULKAN_API VULKAN_API_SC

mutable struct VulkanAPI
  const subset::VulkanAPISubset
  const version::Optional{VersionNumber}
  platforms::Platforms
  authors::Authors
  extensions::Extensions
  "Some specifications are disabled in the Vulkan headers (see https://github.com/KhronosGroup/Vulkan-Docs/issues/1225)."
  disabled_symbols::Set{Symbol}
  extensions_spirv::ExtensionsSPIRV
  capabilities_spirv::CapabilitiesSPIRV
  constants::Constants
  enums::Enums
  bitmasks::Bitmasks
  flags::Flags
  structs::Structs
  unions::Unions
  functions::Functions
  handles::Handles
  constructors::Constructors
  destructors::Destructors
  aliases::Aliases
  structure_types::Dictionary{Symbol,Symbol}
  core_functions::Vector{Symbol}
  instance_functions::Vector{Symbol}
  device_functions::Vector{Symbol}
  "Symbols defined by the API, excluding aliases."
  symbols::Dictionary{Symbol, Spec}
  symbols_including_aliases::Dictionary{Symbol, Spec}
  VulkanAPI(subset::VulkanAPISubset, version::Optional{VersionNumber}) = new(subset, version)
end

Base.getindex(api::VulkanAPI, symbol::Symbol) = api.symbols_including_aliases[symbol]
Base.get(api::VulkanAPI, symbol::Symbol, default) = get(api.symbols_including_aliases, symbol, default)

download_specification(version::VersionNumber) = download("https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/v$version/xml/vk.xml")
download_specification_video(version::VersionNumber) = download("https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/v$version/xml/video.xml")

function VulkanAPI(version::VersionNumber; include_video_api::Bool = true)
  api = VulkanAPI(download_specification(version), version)
  (version < v"1.2.203" || !include_video_api) && return api
  video_api = VulkanAPI(download_specification_video(version))
  union!(api.structs, video_api.structs)
  union!(api.enums, video_api.enums)
  union!(api.constants, video_api.constants)
  union!(api.extensions, video_api.extensions)
  merge!(api.symbols, video_api.symbols)
  merge!(api.symbols_including_aliases, video_api.symbols_including_aliases)
  api
end

function infer_version_from_filename(xml_file::AbstractString)
  m = match(r"(\d+\.\d+\.\d+).xml$", basename(xml_file))
  isnothing(m) && return nothing
  parse(VersionNumber, m[1])
end

VulkanAPI(xml_file::AbstractString, version = infer_version_from_filename(xml_file)) = VulkanAPI(readxml(xml_file), version)

function VulkanAPI(xml::Document, version = nothing)
  api = VulkanAPI(VULKAN_API, version)
  parse_specification_data!(api, xml)
  extend_enums_and_bitmasks!(api, xml)
  generate_constructors_and_destructors!(api)
  compute_symbols!(api)
  classify_functions!(api)
  return api
end

function parse_specification_data!(api::VulkanAPI, xml::Document)
  api.platforms = Platforms(xml)
  api.authors = Authors(xml)
  api.extensions = extensions = Extensions(xml)
  api.disabled_symbols = Set(foldl(append!, extensions[.!in.(EXTENSION_SUPPORT_VULKAN, extensions.support)].symbols; init = Symbol[]))
  api.aliases = Aliases(xml)
  api.extensions_spirv = ExtensionsSPIRV(xml)
  api.capabilities_spirv = CapabilitiesSPIRV(xml)
  api.constants = Constants(xml, extensions)
  api.enums = Enums(xml, extensions)
  api.bitmasks = Bitmasks(xml, extensions)
  api.flags = Flags(xml, extensions, api.bitmasks, api.disabled_symbols)
  api.structs = Structs(xml, extensions)
  api.unions = Unions(xml, extensions)
  api.functions = Functions(xml, extensions)
  api.handles = Handles(xml, extensions)
  api.structure_types = parse_structure_types(xml)
  return api
end

function extend_enums_and_bitmasks!(api::VulkanAPI, xml::Document)
  for node in findall("//*[@extends and not(@alias)]", xml)
    name = getattr(node, "extends")

    # Extended enum.
    i = findfirst(==(name) ∘ key, api.enums)
    if i !== nothing
      enum = api.enums[i]
      value = SpecConstant(node)
      !in(value, enum.enums) && !in(value.name, api.disabled_symbols) && push!(enum.enums, value)
      continue
    end

    # Extended bitmask.
    i = findfirst(==(name) ∘ key, api.bitmasks)
    if i !== nothing
      bitmask = api.bitmasks[i]
      if haskey(node, "bitpos") && !haskey(node, "value")
        value = SpecBit(node)
        !in(value, bitmask.bits) && !in(value.name, api.disabled_symbols) && push!(bitmask.bits, value)
      elseif haskey(node, "value")
        value = SpecBitCombination(node)
        !in(value, bitmask.combinations) && !in(value.name, api.disabled_symbols) && push!(bitmask.combinations, value)
      end
      continue
    end

    @warn "Unknown type '$name' extended"
  end
  return api
end

function generate_constructors_and_destructors!(api::VulkanAPI)
  api.constructors = Constructors(api.functions, api.handles, api.structs, api.aliases)
  api.destructors = Destructors(api.functions, api.handles)
  return api
end

function compute_symbols!(api::VulkanAPI)
  specs = Spec[]
  append!(specs, api.functions)
  append!(specs, api.structs)
  append!(specs, api.handles)
  append!(specs, api.constants)
  append!(specs, api.enums)
  append!(specs, api.bitmasks)
  for enum in api.enums
    append!(specs, enum.enums)
  end
  for bitmask in api.bitmasks
    append!(specs, bitmask.bits)
    append!(specs, bitmask.combinations)
  end
  api.symbols = sortkeys!(Dictionary(name.(specs), specs))
  symbol_aliases = get_symbol_aliases(api.aliases, api.symbols, api.disabled_symbols)
  api.symbols_including_aliases = sortkeys!(merge!(symbol_aliases, api.symbols))
  return api
end

function get_symbol_aliases(aliases, symbols, disabled_symbols)
  names = Symbol[]
  specs = Spec[]
  for name in keys(aliases.dict)
    in(name, disabled_symbols) && continue
    push!(names, name)
    push!(specs, symbols[follow_alias(name, aliases)])
  end
  Dictionary(names, specs)
end

function classify_functions!(api::VulkanAPI)
  api.core_functions = Symbol[]
  api.instance_functions = Symbol[]
  api.device_functions = Symbol[]
  for fname in unique!([api.functions.name; [x for (x, alias) in pairs(api.aliases.dict) if haskey(api.functions, alias)]])
    spec = api.functions[follow_alias(fname, api.aliases)]
    t = follow_alias(spec.params[1], api.aliases)
    h = get(api.handles, t.type, nothing)
    if isnothing(h)
      push!(api.core_functions, fname)
    else
      parents = parent_hierarchy(h, api.handles)
      if :VkDevice in parents
        push!(api.device_functions, fname)
      elseif :VkInstance in parents
        push!(api.instance_functions, fname)
      end
    end
  end
  return api
end
