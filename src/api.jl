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
  structure_types::Dict{Symbol,Symbol}
  core_functions::Vector{Symbol}
  instance_functions::Vector{Symbol}
  device_functions::Vector{Symbol}
  "All symbols defined by the API, excluding aliases."
  all_symbols::Dict{Symbol, Spec}
end

function VulkanAPI(version::VersionNumber)
  xml_file = download("https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/v$version/xml/vk.xml")
  VulkanAPI(xml_file, version)
end

VulkanAPI(xml_file::AbstractString, version = nothing) = VulkanAPI(readxml(xml_file), version)

function VulkanAPI(xml::Document, version = nothing)
  platforms = Platforms(xml)
  authors = Authors(xml)
  extensions = Extensions(xml)
  disabled_symbols = Set(foldl(append!, extensions[extensions.is_disabled].symbols; init = Symbol[]))
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

  # Extend all types with core and extension values.
  extensible = [enums..., bitmasks..., structs...]
  for node in findall("//*[@extends and not(@alias)]", xml)
    spec = extensible[findfirst(spec -> name(spec) == Symbol(node["extends"]), extensible)]
    @switch spec begin
      @case ::SpecBitmask
      if haskey(node, "bitpos") && !haskey(node, "value")
        push!(spec.bits, SpecBit(node))
      elseif haskey(node, "value")
        push!(spec.combinations, SpecBitCombination(node))
      end
      @case ::SpecEnum
      push!(spec.enums, SpecConstant(node))
    end
  end

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
    Dict(name.(all_specs) .=> all_specs),
  )
end

aliases(name) = VULKAN_API[].aliases[name]
follow_alias(name) = follow_alias(VULKAN_API[].aliases, name)
isalias(name) = isalias(VULKAN_API[].aliases, name)
hasalias(name) = hasalias(VULKAN_API[].aliases, name)

function classify_functions(functions::Functions, aliases::Aliases, handles::Handles)
  core_functions = Symbol[]
  instance_functions = Symbol[]
  device_functions = Symbol[]
  for fname in unique!([functions.name; [x for (x, alias) in aliases.dict if haskey(functions, alias)]])
    spec = functions[follow_alias(fname, aliases)]
    t = follow_alias(spec.params[1], aliases)
    h = get(handles, t, nothing)
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
