struct VulkanAPI
  version::Optional{VersionNumber}
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
  platforms = Platforms(xml)
  authors = Authors(xml)
  extensions = Extensions(xml)
  disabled_symbols = Set(foldl(append!, extensions[.!in.(EXTENSION_SUPPORT_VULKAN, extensions.support)].symbols; init = Symbol[]))
  aliases = Aliases(xml)
  extensions_spirv = ExtensionsSPIRV(xml)
  capabilities_spirv = CapabilitiesSPIRV(xml)
  constants = Constants(xml, extensions)
  enums = Enums(xml, extensions)
  bitmasks = Bitmasks(xml, extensions)
  flags = Flags(xml, extensions, bitmasks, disabled_symbols)
  structs = Structs(xml, extensions)
  unions = Unions(xml, extensions)
  functions = Functions(xml, extensions)
  handles = Handles(xml, extensions)
  constructors = Constructors(functions, handles, structs, aliases)
  destructors = Destructors(functions, handles)

  # Extend all types with core and extension values.
  extensible = [enums..., bitmasks..., structs...]
  for node in findall("//*[@extends and not(@alias)]", xml)
    spec = extensible[findfirst(spec -> name(spec) == Symbol(node["extends"]), extensible)]
    @switch spec begin
      @case ::SpecBitmask
      if haskey(node, "bitpos") && !haskey(node, "value")
        value = SpecBit(node)
        !in(value, spec.bits) && !in(value.name, disabled_symbols) && push!(spec.bits, value)
      elseif haskey(node, "value")
        value = SpecBitCombination(node)
        !in(value, spec.combinations) && !in(value.name, disabled_symbols) && push!(spec.combinations, value)
      end
      @case ::SpecEnum
      value = SpecConstant(node)
      !in(value, spec.enums) && !in(value.name, disabled_symbols) && push!(spec.enums, value)
    end
  end

  all_specs = [
    functions...,
    structs...,
    handles...,
    constants...,
    enums...,
    (enums.enums...)...,
    bitmasks...,
    (bitmasks.bits...)...,
    (bitmasks.combinations...)...
  ]
  symbols = sortkeys!(Dictionary(name.(all_specs), all_specs))
  symbols_including_aliases = sortkeys!(merge!(dictionary([name => symbols[follow_alias(name, aliases)] for name in keys(aliases.dict) if !in(name, disabled_symbols)]), symbols))

  structure_types = parse_structure_types(xml)
  VulkanAPI(
    version,
    platforms,
    authors,
    extensions,
    disabled_symbols,
    extensions_spirv,
    capabilities_spirv,
    constants,
    enums,
    bitmasks,
    flags,
    structs,
    unions,
    functions,
    handles,
    constructors,
    destructors,
    aliases,
    structure_types,
    classify_functions(functions, aliases, handles)...,
    symbols,
    symbols_including_aliases,
  )
end

function classify_functions(functions::Functions, aliases::Aliases, handles::Handles)
  core_functions = Symbol[]
  instance_functions = Symbol[]
  device_functions = Symbol[]
  for fname in unique!([functions.name; [x for (x, alias) in pairs(aliases.dict) if haskey(functions, alias)]])
    spec = functions[follow_alias(fname, aliases)]
    t = follow_alias(spec.params[1], aliases)
    h = get(handles, t.type, nothing)
    if isnothing(h)
      push!(core_functions, fname)
    else
      parents = parent_hierarchy(h, handles)
      if :VkDevice in parents
        push!(device_functions, fname)
      elseif :VkInstance in parents
        push!(instance_functions, fname)
      end
    end
  end
  (core_functions, instance_functions, device_functions)
end
