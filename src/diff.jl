struct RemovedSymbol
  name::Symbol
  was_provisional::Bool
end

struct Diff
  old::VulkanAPI
  new::VulkanAPI
  removed::Vector{RemovedSymbol}
  added::Vector{Symbol}
end

function isbreaking(symbol::RemovedSymbol)
  symbol.was_provisional && return false
  name = string(symbol.name)
  contains(name, r"(VIDEO|STD|Video|Std|RESERVED)") && return false
  endswith(name, r"(_EXTENSION_NAME|_SPEC_VERSION)") && return false
  return true
end

function Diff(old::VulkanAPI, new::VulkanAPI)
  removed_symbols = setdiff(keys(old.symbols_including_aliases), keys(new.symbols_including_aliases))
  removed = map(collect(removed_symbols)) do symbol
    spec = old[symbol]
    extension = if isa(spec, SpecBitCombination) || isa(spec, SpecBit)
      i = @match spec begin
        ::SpecBitCombination => findfirst(x -> in(spec, x.combinations), old.bitmasks)::Int
        ::SpecBit => findfirst(x -> in(spec, x.bits), old.bitmasks)::Int
      end
      get(old.extensions, old.bitmasks[i], nothing)
    else
      get(old.extensions, spec, nothing)
    end
    was_provisional = isnothing(extension) || extension.is_provisional
    RemovedSymbol(symbol, was_provisional)
  end
  added = collect(setdiff(keys(new.symbols_including_aliases), keys(old.symbols_including_aliases)))
  Diff(old, new, removed, added)
end
