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

function Base.show(io::IO, ::MIME"text/plain", ext::SpecExtension)
  @match ext.type begin
    &EXTENSION_TYPE_INSTANCE => print(io, "Instance extension ")
    &EXTENSION_TYPE_DEVICE => print(io, "Device extension ")
    &EXTENSION_TYPE_ANY => print(io, "Extension ")
  end
  print(io, ext.name)
  inline_infos = String[]
  ext.is_provisional && push!(inline_infos, "provisional")
  ext.support == EXTENSION_SUPPORT_DISABLED && push!(inline_infos, "disabled")
  ext.support == EXTENSION_SUPPORT_VULKAN_SC && push!(inline_infos, "Vulkan SC only")
  !isnothing(ext.promoted_to) && push!(inline_infos, "promoted in version $(ext.promoted_to)")
  !isempty(inline_infos) && print(io, " (", join(inline_infos, ", "), ')')
  println(io)
  ext.platform ∉ (PLATFORM_NONE, PLATFORM_PROVISIONAL) && println(io, "• Platform: ", replace(string(ext.platform), "PLATFORM_" => ""))
  !isempty(ext.requirements) && println(io, "• Depends on: ", join(ext.requirements, ", "))
  n = length(ext.symbols)
  if n > 0
    println(io, "• $n symbols: ")
    limit = 8
    foreach(enumerate(sort(ext.symbols))) do (i, symbol)
      (i ≤ limit / 2 || i > n - limit ÷ 2) && (i == n ? print : println)(io, "  ∘ ", symbol)
      i == limit ÷ 2 && println(io, "  ⋮")
    end
  end
  if !isnothing(ext.author)
    print(io, "\n• From: ", ext.author)
  end
end

function Base.show(io::IO, mime::MIME"text/plain", collection::Collection)
  print(io, typeof(collection), " with data ")
  show(io, mime, collection.data)
end

vulkan_version(api::VulkanAPI) = isnothing(api.version) ? "unknown version" : "version $(api.version)"

function Base.show(io::IO, api::VulkanAPI)
  print(io, typeof(api), '(' * vulkan_version(api), " with ", length(api.structs) + length(api.unions), " types and ", length(api.functions), " functions - ", length(api.symbols) + length(api.aliases.dict), " symbols in total, including ", length(api.aliases.dict), " aliases)")
end

Base.show(io::IO, ::MIME"text/plain", removed::RemovedSymbol) = print(io, ':', removed.name, " (", removed.was_provisional ? "provisional" : "BREAKING", ')')

function Base.show(io::IO, mime::MIME"text/plain", diff::Diff)
  println(io, "Diff from Vulkan (", vulkan_version(diff.old), ") to Vulkan (", vulkan_version(diff.new), "):")
  println(io, "● Removed symbols: ", sprint(show, mime, diff.removed; context = :limit => true))
  println(io, "● Added symbols: ", sprint(show, mime, diff.added; context = :limit => true))
end
