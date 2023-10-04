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

isbreaking(symbol::RemovedSymbol) = !symbol.was_provisional && !contains(string(symbol.name), r"(VIDEO|STD|Video|Std|RESERVED)")

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
