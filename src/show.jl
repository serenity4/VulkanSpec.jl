function Base.show(io::IO, spec::Union{SpecStructMember,SpecFuncParam})
  props = string.([spec.requirement])
  spec.is_constant && push!(props, "constant")
  spec.is_externsync && push!(props, "externsync")
  is_arr(spec) && push!(props, "with length $(spec.len)")
  !isempty(spec.arglen) && push!(props, string("length of ", join(spec.arglen, ' ')))
  print(io, join(string.(vcat(typeof(spec), spec.type, spec.name, props)), ' '))
end

print_parent_info(io::IO, spec::Union{SpecStruct,SpecFunc}, props) =
println(io, join(string.(vcat(typeof(spec), spec.name, props)), ' '))

print_children(io::IO, spec::Union{SpecStruct,SpecFunc}) = println.(Ref(io), string.("    ", children(spec)))

function Base.show(io::IO, spec::SpecStruct)
  props = string.([spec.type])
  spec.is_returnedonly && push!(props, "returnedonly")
  !isempty(spec.extends) && push!(props, "extends $(spec.extends)")
  print_parent_info(io, spec, props)
  print_children(io, spec)
end

function Base.show(io::IO, spec::SpecFunc)
  props = string.([spec.type, spec.return_type])
  !isempty(spec.render_pass_compatibility) && push!(props, string("to be executed ", join(map(spec.render_pass_compatibility) do compat
      @match compat begin
        ::RenderPassInside => "inside"
        ::RenderPassOutside => "outside"
      end
    end, " and "), " render passes"))
  !isempty(spec.queue_compatibility) && push!(props, " (compatible with $(join(string.(spec.queue_compatibility), ", ")) queues)")
  print_parent_info(io, spec, props)
  print_children(io, spec)
end

function Base.show(io::IO, mime::MIME"text/plain", ext::SpecExtension)
  @match ext.type begin
    &EXTENSION_TYPE_INSTANCE => print(io, "Instance extension ")
    &EXTENSION_TYPE_DEVICE => print(io, "Device extension ")
    &EXTENSION_TYPE_ANY => print(io, "Extension ")
  end
  print(io, ext.name)
  inline_infos = String[]
  ext.is_provisional && push!(inline_infos, "provisional")
  ext.disabled && push!(inline_infos, "disabled")
  ext.applicable == [VULKAN_SC] && push!(inline_infos, "Vulkan SC only")
  !isnothing(ext.promoted_to) && push!(inline_infos, "promoted in version $(ext.promoted_to)")
  !isempty(inline_infos) && print(io, " (", join(inline_infos, ", "), ')')
  ext.platform ∉ (PLATFORM_NONE, PLATFORM_PROVISIONAL) && print(io, "\n• Platform: ", replace(string(ext.platform), "PLATFORM_" => ""))
  !isempty(ext.requirements) && print(io, "\n• Depends on: ", join(ext.requirements, ", "))
  n = length(ext.groups)
  if n > 0
    print(io, "\n• $n symbol groups: ")
    for (i, group) in enumerate(ext.groups)
      i > 1 && println(io)
      print(io, "\n  ", something(group.description, "Group #$i"))
      for symbol in group.symbols
        print(io, "\n  ∘ ")
        show(io, mime, symbol)
      end
    end
  end
  if !isnothing(ext.author)
    print(io, "\n• From: ", ext.author)
  end
end

function Base.show(io::IO, mime::MIME"text/plain", set::SymbolSet)
  print(io, "Symbol set '", set.name, "' with ", length(set), " symbol groups:")
  for (i, group) in enumerate(set)
    print(io, "\n  ", something(group.description, "Group #$i"))
    printstyled(io, " (", length(group), " symbols)"; color = :light_black)
  end
end

function Base.show(io::IO, mime::MIME"text/plain", symbol::SymbolInfo)
  color = (104, 179, 116)[Int(symbol.type)]
  printstyled(io, symbol.name; color)
  symbol.deprecated && print(io, " (deprecated)"; color = :light_black)
end

function Base.show(io::IO, mime::MIME"text/plain", collection::Collection)
  print(io, typeof(collection), " with data ")
  show(io, mime, collection.data)
end

vulkan_version(api::VulkanAPI) = isnothing(api.version) ? "unknown version" : "version $(api.version)"

function Base.show(io::IO, api::VulkanAPI)
  print(io, typeof(api), '(' * vulkan_version(api), " with ", length(api.structs) + length(api.unions), " types and ", length(api.functions), " functions - ", length(api.symbols) + length(api.aliases.dict), " symbols in total, including ", length(api.aliases.dict), " aliases)")
end

function Base.show(io::IO, ::MIME"text/plain", removed::RemovedSymbol)
  print(io, ':', removed.name)
  isbreaking(removed) || return
  print(io, " (", removed.was_provisional ? "provisional" : "BREAKING", ')')
end

function Base.show(io::IO, mime::MIME"text/plain", diff::Diff)
  println(io, "Diff from Vulkan (", vulkan_version(diff.old), ") to Vulkan (", vulkan_version(diff.new), "):")
  println(io, "● Removed symbols: ", sprint(show, mime, diff.removed; context = :limit => true))
  println(io, "● Added symbols: ", sprint(show, mime, diff.added; context = :limit => true))
end
