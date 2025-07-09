const queue_map = dictionary([
    :compute => QueueCompute(),
    :graphics => QueueGraphics(),
    :transfer => QueueTransfer(),
    :sparse_binding => QueueSparseBinding(),
    :decode => QueueVideoDecode(),
    :encode => QueueVideoEncode(),
    :opticalflow => QueueOpticalFlow(),
])

const render_pass_compatibility_map = dictionary([
    :both => [RenderPassInside(), RenderPassOutside()],
    :inside => [RenderPassInside()],
    :outside => [RenderPassOutside()],
])

function SpecStructMember(node::Node, parent::SpecStruct)
    SpecStructMember(
        parent,
        extract_identifier(node),
        extract_type(node),
        is_constant(node),
        externsync(node),
        PARAM_REQUIREMENT(node),
        len(node),
        arglen(node, neighbor_type = "member"),
        !parse(Bool, getattr(node, "noautovalidity", default = "false", symbol = false)),
    )
end

function SpecStruct(node::Node)
    name_str = node["name"]
    returnedonly = haskey(node, "returnedonly")
    type = @match returnedonly begin
        true => STYPE_PROPERTY
        _ && if occursin("CreateInfo", name_str)
        end => STYPE_CREATE_INFO
        _ && if occursin("AllocateInfo", name_str)
        end => STYPE_ALLOCATE_INFO
        _ && if occursin("Info", name_str)
        end => STYPE_GENERIC_INFO
        _ => STYPE_DATA
    end
    extends = @match struct_csv = getattr(node, "structextends", symbol = false) begin
        ::String => Symbol.(split(struct_csv, ','))
        ::Nothing => []
    end
    SpecStruct(
        Symbol(name_str),
        type,
        returnedonly,
        extends,
        findall("./member", node),
    )
end

function SpecUnion(node::Node)
    members = findall("./member", node)
    selectors = getattr.(members, "selection")
    SpecUnion(
        getattr(node, "name"),
        extract_type.(members),
        extract_identifier.(members),
        filter(!isnothing, selectors),
        haskey(node, "returnedonly"),
    )
end

SpecFuncParam(node::Node, parent::SpecFunc) = SpecFuncParam(
    parent,
    extract_identifier(node),
    extract_type(node),
    is_constant(node),
    externsync(node),
    PARAM_REQUIREMENT(node),
    len(node),
    arglen(node),
    !parse(Bool, getattr(node, "noautovalidity", default = "false", symbol = false)),
)

function SpecFunc(node::Node)
    name = command_name(node)
    queues = @match getattr(node, "queues", symbol = false) begin
        qs::String => [queue_map[Symbol(q)] for q ∈ split(qs, ',')]
        ::Nothing => []
    end
    rp_reqs = @match getattr(node, "renderpass") begin
        x::Symbol => render_pass_compatibility_map[x]
        ::Nothing => []
    end
    ctype = @match findfirst(startswith.(string(name), ["vkCreate", "vkDestroy", "vkAllocate", "vkFree", "vkCmd"])) begin
        i::Integer => FunctionType(i - 1)
        if any(startswith.(string(name), ["vkGet", "vkEnumerate"]))
        end => FTYPE_QUERY
        _ => FTYPE_OTHER
    end
    return_type = extract_type(findfirst("./proto", node))
    codes(type) = Symbol.(filter(!isempty, split(getattr(node, type; default = "", symbol = false), ',')))
    SpecFunc(
        name,
        ctype,
        return_type,
        rp_reqs,
        queues,
        findall("./param[not(@api) or @api='vulkan']", node),
        codes("successcodes"),
        codes("errorcodes"),
    )
end

SpecEnum(node::Node) = SpecEnum(getattr(node, "name"), StructVector(SpecConstant.(findall("./enum[@name and not(@alias)]", node))))

SpecBit(node::Node) = SpecBit(
  getattr(node, "name"),
  parse(Int, getattr(node, "bitpos", symbol = false)),
)

SpecBitCombination(node::Node) = SpecBitCombination(
  getattr(node, "name"),
  parse(UInt, getattr(node, "value", symbol = false)),
)

function SpecBitmask(node::Node)
  name = getattr(node, "name")
  bits = StructVector(SpecBit.(findall("./enum[not(@alias) and not(@value)]", node)))
  combinations = StructVector(SpecBitCombination.(findall("./enum[not(@alias) and @value]", node)))
  width = parse(Int, getattr(node, "bitwidth", symbol = false, default = "32"))
  SpecBitmask(name, bits, combinations, width)
end

function SpecFlag(node::Node, bitmasks::Bitmasks, disabled_symbols)
  name = Symbol(findfirst("./name", node).content)
  typealias = Symbol(findfirst("./type", node).content)
  bitmask = if haskey(node, "requires")
    bitmask_name = getattr(node, "requires")
    bitmask_name in disabled_symbols ? nothing : bitmasks[bitmask_name]
  else
    nothing
  end
  SpecFlag(name, typealias, bitmask)
end

function SpecHandle(node::Node)
  is_dispatchable = findfirst("./type", node).content == "VK_DEFINE_HANDLE"
  name = Symbol(findfirst("./name", node).content)
  SpecHandle(name, getattr(node, "parent"), is_dispatchable)
end

function SpecConstant(node::Node)
  name = Symbol(haskey(node, "name") ? node["name"] : findfirst("./name", node).content)
  value = if haskey(node, "offset")
    ext_value = -1 + parse(Int, something(
      getattr(node, "extnumber", symbol = false),
      getattr(node.parentnode.parentnode, "number", symbol = false),
    ))
    offset = parse(Int, node["offset"])
    sign = (1 - 2 * (getattr(node, "dir", default = "", symbol = false) == "-"))
    sign * Int(1e9 + ext_value * 1e3 + offset)
  elseif haskey(node, "value")
    @match node["value"] begin
      "(~0U)" => :(typemax(UInt32))
      "(~0ULL)" => :(typemax(UInt64))
      "(~0U-1)" => :(typemax(UInt32) - 1)
      "(~0U-2)" => :(typemax(UInt32) - 2)
      "1000.0f" => :(1000.0f0)
      str::String && if contains(str, "&quot;") end => replace(str, "&quot;" => "")
      str => Meta.parse(str)
    end
  elseif haskey(node, "category")
    @match cat = node["category"] begin
      ("basetype" || "bitmask") => @match type = findfirst("./type", node) begin
        ::Nothing && if cat == "basetype" end => :Cvoid
        ::Node => translate_c_type(Symbol(type.content))
      end
    end
  else
    error("Unknown constant specification for node $node")
  end
  SpecConstant(name, value)
end

function SpecAlias(node::Node, aliases::Aliases, specs)
  name = getattr(node, "name")
  alias = follow_alias(name, aliases)
  SpecAlias(name, specs[alias])
end

PlatformType(::Nothing) = PLATFORM_NONE
PlatformType(type::String) = getproperty(@__MODULE__, Symbol("PLATFORM_", uppercase(type)))

function SpecExtension(node::Node)
  exttype = @match getattr(node, "type") begin
    :instance => EXTENSION_TYPE_INSTANCE
    :device => EXTENSION_TYPE_DEVICE
    ::Nothing => EXTENSION_TYPE_ANY
    t => error("Unknown extension type '$t'")
  end
  requires = getattr(node, "requires", default = "", symbol = false)
  requirements = isempty(requires) ? String[] : split(requires, ',')
  supported = split(node["supported"], ',')
  applicable = parse_applicable_apis(supported)
  disabled = in("disabled", supported)
  unknown = filter(!in(("vulkan", "vulkansc", "disabled")), supported)
  !isempty(unknown) && error("Unknown extension support value(s) $(join('`' .* string.(unknown) .* '`', ", "))")
  platform = PlatformType(getattr(node, "platform", symbol = false))
  groups = SymbolGroup.(findall("./require", node))
  promoted_to = getattr(node, "promotedto", symbol = false)
  promoted_to = something(version_number(promoted_to), promoted_to, Some(nothing))
  SpecExtension(
    node["name"],
    exttype,
    requirements,
    applicable,
    getattr(node, "author", symbol = false),
    groups,
    platform,
    platform == PLATFORM_PROVISIONAL,
    disabled,
    promoted_to,
    getattr(node, "deprecatedby", symbol = false),
  )
end

function queue_compatibility(node::Node)
  @when let _ = node, if haskey(node, "queues") end
    queue.(split(node["queues"], ','))
  end
end

externsync(node::Node) = haskey(node, "externsync") && node["externsync"] ≠ "false"

function len(node::Node)
  haskey(node, "altlen") && return Meta.parse(node["altlen"])
  @match getattr(node, "len", symbol = false) begin
    val::Nothing => nothing
    val => begin
      val_arr = filter(≠("null-terminated"), split(val, ','))
      if length(val_arr) > 1
        if length(last(val_arr)) == 1 && isdigit(first(last(val_arr))) # array of pointers, length is unaffected
          pop!(val_arr)
        else
          error("Failed to parse 'len' parameter '$val' for $(node.parentnode["name"]).")
        end
      end
      isempty(val_arr) ? nothing : Symbol(first(val_arr))
    end
  end
end

function arglen(node::Node; neighbor_type = "param")
  neighbors = findall("../$neighbor_type", node)
  arg_name = name(node)
  map(name, filter(x -> len(x) == arg_name, neighbors))
end

SpecPlatform(node::Node) = SpecPlatform(PlatformType(node["name"]), node["comment"])
AuthorTag(node::Node) = AuthorTag(node["name"], node["author"])

function SpecExtensionSPIRV(node::Node)
  versions = map(Base.Fix2(getindex, "version"), findall(".//enable[@version]", node))
  enabling_exts = map(Base.Fix2(getindex, "extension"), findall(".//enable[@extension]", node))
  SpecExtensionSPIRV(node["name"], promoted_in(versions), enabling_exts)
end

function version_number(str::AbstractString)
  m = match(r"VK(?:_API)?_VERSION_(\d+)_(\d+)", str)
  isnothing(m) && return nothing
  VersionNumber(parse(Int, m.captures[1]), parse(Int, m.captures[2]))
end
version_number(::Nothing) = nothing

function extract_version_ext(node::Node)
    requires = split(getattr(node, "requires"; default = "", symbol = false), ',')
    core_version = nothing
    filter!(requires) do req
      version = version_number(req)
      isnothing(version) && (core_version = version)
      isnothing(version)
    end
    core_version, isempty(requires) ? nothing : only(requires)
end

function SpecCapabilitySPIRV(node::Node)
  versions = map(Base.Fix2(getindex, "version"), findall(".//enable[@version]", node))
  enabling_exts = map(Base.Fix2(getindex, "extension"), findall(".//enable[@extension]", node))
  enabling_structs = map(findall(".//enable[@struct]", node)) do node
    FeatureCondition(getattr(node, "struct"), getattr(node, "feature"), extract_version_ext(node)...)
  end
  enabling_props = map(findall(".//enable[@property]", node)) do node
    value = getattr(node, "value")
    bit = value == :VK_TRUE ? nothing : value
    PropertyCondition(getattr(node, "property"), getattr(node, "member"), extract_version_ext(node)..., isnothing(bit), value)
  end
  SpecCapabilitySPIRV(getattr(node, "name"), promoted_in(versions), enabling_exts, enabling_structs, enabling_props)
end

function promoted_in(versions)
  isempty(versions) && return nothing
  version_number(only(versions))
end

function spec_by_field(specs, field, value)
  specs[findall(==(value), getproperty(specs, field))]
end

function spec_by_name(specs, name)
  specs = spec_by_field(specs, :name, name)
  if !isempty(specs)
    length(specs) == 1 || error("Non-uniquely identified spec '$name': $specs")
    first(specs)
  else
    nothing
  end
end

function parse_structure_types(xml)
  stype_vals = findall("//member[@values]", xml)
  res = Dictionary{Symbol,Symbol}()
  for stype ∈ stype_vals
    type = stype.parentnode["name"]
    stype_value = stype["values"]
    insert!(res, Symbol(type), Symbol(stype_value))
  end
  sortkeys!(res)
end

nodes(::Type{SpecPlatform}, xml::Document) = findall("//platform", xml)
nodes(::Type{AuthorTag}, xml::Document) = findall("//tag", xml)
nodes(::Type{SpecExtension}, xml::Document) = findall("//extension", xml)
nodes(::Type{SpecExtensionSPIRV}, xml::Document) = findall("//spirvextension", xml)
nodes(::Type{SpecCapabilitySPIRV}, xml::Document) = findall("//spirvcapability", xml)
nodes(::Type{SpecEnum}, xml::Document) = findall("//enums[@type = 'enum' and not(@alias)]", xml)
nodes(::Type{SpecBitmask}, xml::Document) = findall("//enums[@type = 'bitmask' and not(@alias)]", xml)
nodes(::Type{SpecFlag}, xml::Document) = findall("//type[@category = 'bitmask' and not(@alias)]", xml)
nodes(::Type{SpecConstant}, xml::Document) = [findall("//enums[@name = 'API Constants']/*[@value and @name]", xml); findall("//extension/require/enum[not(@extends) and not(@alias) and @value]", xml); findall("/registry/types/type[@category = 'basetype' or @category = 'bitmask' and not(@alias) and (not(@api) or @api='vulkan')]", xml)]
nodes(::Type{SpecStruct}, xml::Document) = findall("//type[@category = 'struct' and not(@alias)]", xml)
nodes(::Type{SpecUnion}, xml::Document) = findall("//type[@category = 'union' and not(@alias)]", xml)
nodes(::Type{SpecFunc}, xml::Document) = findall("//command[not(@name) and (not(@api) or @api='vulkan')]", xml)
nodes(::Type{SpecHandle}, xml::Document) = findall("//type[@category = 'handle' and not(@alias)]", xml)
function nodes(::Type{SpecAlias}, xml::Document)
  aliases = findall("//*[@alias and @name]", xml)
  filter!(aliases) do alias
    parent = x.parentnode.parentnode
    parent.name ≠ "extension" || getattr(parent, "supported") ≠ :disabled
  end
end
nodes(::Type{SymbolSet}, xml::Document) = findall("//feature[@api]", xml)
