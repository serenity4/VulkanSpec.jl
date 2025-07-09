mutable struct VulkanAPI
  const applicable::ApplicableAPI
  const version::Optional{VersionNumber}
  platforms::Platforms
  authors::Authors
  extensions::Extensions
  "Some specifications are disabled in the Vulkan headers (see https://github.com/KhronosGroup/Vulkan-Docs/issues/1225)."
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
  sets::SymbolSets
  VulkanAPI(subset::ApplicableAPI, version::Optional{VersionNumber}) = new(subset, version)
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
  api = VulkanAPI(VULKAN, version)
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
  api.aliases = Aliases(xml)
  api.extensions_spirv = ExtensionsSPIRV(xml)
  api.capabilities_spirv = CapabilitiesSPIRV(xml)
  api.constants = Constants(xml)
  api.enums = Enums(xml)
  api.bitmasks = Bitmasks(xml)
  api.flags = Flags(xml, api.bitmasks)
  api.structs = Structs(xml)
  api.unions = Unions(xml)
  api.functions = Functions(xml)
  api.handles = Handles(xml)
  api.structure_types = parse_structure_types(xml)
  api.sets = SymbolSets(xml)
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
      !in(value, enum.enums) && push!(enum.enums, value)
      continue
    end

    # Extended bitmask.
    i = findfirst(==(name) ∘ key, api.bitmasks)
    if i !== nothing
      bitmask = api.bitmasks[i]
      if haskey(node, "bitpos") && !haskey(node, "value")
        value = SpecBit(node)
        !in(value, bitmask.bits) && push!(bitmask.bits, value)
      elseif haskey(node, "value")
        value = SpecBitCombination(node)
        !in(value, bitmask.combinations) && push!(bitmask.combinations, value)
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
  select_first_occurences!(specs)
  names = name.(specs)
  api.symbols = sortkeys!(Dictionary(names, specs))
  symbol_aliases = get_symbol_aliases(api.aliases, api.symbols)
  api.symbols_including_aliases = sortkeys!(merge!(symbol_aliases, api.symbols))
  return api
end

# Workaround for the fact that redundancies may be introduced across
# extension-defined symbols and promoted (set-defined) symbols.
function select_first_occurences!(specs)
  seen = Set{Symbol}()
  indices = Int[]
  for (i, spec) in enumerate(specs)
    name = @__MODULE__().name(spec)
    in(name, seen) && push!(indices, i)
    push!(seen, name)
  end
  splice!(specs, indices)
end

function get_symbol_aliases(aliases, symbols)
  names = Symbol[]
  specs = Spec[]
  for name in keys(aliases.dict)
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

function filter_applicable_symbols(api::VulkanAPI)
  vulkan_version_sets = filter(x -> in(VULKAN, x.applicable), api.sets)
  version = @something(api.version, vulkan_version_sets[end].version)
  symbols = Symbol[]
  for set in vulkan_version_sets[1:(1 + version.minor)]
    append!(symbols, defined_symbols(set))
  end
  for extension in api.extensions
    in(VULKAN, extension.applicable) || continue
    for group in extension.groups
      isempty(group.applicable) || in(VULKAN, group.applicable) || continue
      append!(symbols, defined_symbols(group))
    end
  end
  for symbol in symbols
    isalias(symbol, api.aliases) && push!(symbols, follow_alias(symbol, api.aliases))
  end
  return trim_for_symbols(api, Set(symbols), version)
end

function trim_for_symbols(from::VulkanAPI, symbols, version)
  api = VulkanAPI(from.applicable, version)
  api.platforms = copy(from.platforms)
  api.authors = copy(from.authors)
  api.extensions_spirv = copy(from.extensions_spirv)
  api.capabilities_spirv = copy(from.capabilities_spirv)

  api.sets = filter(deepcopy(from.sets)) do set
    in(VULKAN, set.applicable) || return false
    filter!(x -> in(VULKAN, x.applicable), set.groups)
    return !isempty(set)
  end
  api.extensions = filter(deepcopy(from.extensions)) do extension
    in(VULKAN, extension.applicable) || return false
    filter!(x -> in(VULKAN, x.applicable), extension.groups)
    return !isempty(extension.groups)
  end
  api.structs = filter(in(symbols) ∘ name, from.structs)
  api.unions = filter(in(symbols) ∘ name, from.unions)
  api.functions = filter(in(symbols) ∘ name, from.functions)
  api.enums = filter(deepcopy(from.enums)) do enum
    in(name(enum), symbols) || return false
    filter!(in(symbols) ∘ name, enum.enums)
    return !isempty(enum.enums)
  end
  api.bitmasks = filter(deepcopy(from.bitmasks)) do bitmask
    in(name(bitmask), symbols) || return false
    filter!(in(symbols) ∘ name, bitmask.bits)
    filter!(in(symbols) ∘ name, bitmask.combinations)
    return !isempty(bitmask.bits)
  end
  api.flags = filter(in(symbols) ∘ name, from.flags)
  api.constants = filter(in(symbols) ∘ name, from.constants)
  api.handles = filter(in(symbols) ∘ name, from.handles)
  api.aliases = trim_aliases(from, symbols)
  api.structure_types = trim_structure_types(from, symbols)
  generate_constructors_and_destructors!(api)
  compute_symbols!(api)
  classify_functions!(api)
  return api
end

function trim_aliases(from::VulkanAPI, symbols)
  aliases = Dictionary{Symbol,Symbol}()
  for (alias, aliased) in pairs(from.aliases.dict)
    in(alias, symbols) || continue
    in(aliased, symbols) || continue
    insert!(aliases, alias, aliased)
  end
  sortkeys!(aliases)
  verts, graph = compute_alias_graph(aliases)
  return Aliases(aliases, verts, graph)
end

function trim_structure_types(from::VulkanAPI, symbols)
  structure_types = Dictionary{Symbol,Symbol}()
  for (sname, stype) in pairs(from.structure_types)
    in(sname, symbols) || continue
    in(stype, symbols) || continue
    insert!(structure_types, sname, stype)
  end
  return structure_types
end
