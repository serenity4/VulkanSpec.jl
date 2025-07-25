"""
Specification for an alias of the form `const <name> = <alias>`.
"""
struct SpecAlias{S<:Spec} <: Spec
    "Name of the new alias."
    name::Symbol
    "Aliased specification element."
    alias::S
end

struct Aliases
  dict::Dictionary{Symbol,Symbol}
  verts::Vector{Symbol}
  graph::SimpleDiGraph{Int64}
end

function Aliases(xml::Document)
  dict = dictionary(Symbol(alias["name"]) => Symbol(alias["alias"]) for alias ∈ findall("//*[@alias and not(@feature)]", xml))
  sortkeys!(dict)
  verts, graph = compute_alias_graph(dict)
  Aliases(dict, verts, graph)
end

function compute_alias_graph(aliases)
  verts = unique(vcat(collect(keys(aliases)), collect(values(aliases))))
  graph = SimpleDiGraph(length(verts))
  for (j, (src, dst)) ∈ enumerate(pairs(aliases))
    i = findfirst(==(dst), verts)
    add_edge!(graph, i, j)
  end
  return verts, graph
end

"Whether this type is an alias for another name."
isalias(name, aliases::Aliases) = name ∈ keys(aliases.dict)
"Whether an alias was built from this name."
hasalias(name, aliases::Aliases) = name ∈ values(aliases.dict)

function Base.get(default, aliases::Aliases, name::Symbol)
  index = findfirst(==(name), aliases.verts)
  isnothing(index) && return default()
  [aliases.verts[w] for w in outneighbors(aliases.graph, index)]
end
Base.get(aliases::Aliases, name::Symbol, value) = get(Returns(value), aliases, name)
Base.getindex(aliases::Aliases, name::Symbol) = get(() -> throw(KeyError(name)), aliases, name)
Base.length(aliases::Aliases) = length(aliases.dict)

function follow_alias(index::Integer, aliases::Aliases)
  indices = inneighbors(aliases.graph, index)
  if isempty(indices)
    aliases.verts[index]
  elseif length(indices) > 1
    error("More than one indices returned for $(aliases.verts[index]) when following alias $(getindex.(Ref(aliases.verts), indices))")
  else
    i = first(indices)
    if i == index
      aliases.verts[i]
    else
      follow_alias(i, aliases)
    end
  end
end

function follow_alias(name, aliases::Aliases)
  index = findfirst(==(name), aliases.verts)
  isnothing(index) ? name : follow_alias(index, aliases)
end
