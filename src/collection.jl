abstract type Spec end

name(spec::Spec) = spec.name
key(spec::Spec) = name(spec)

abstract type Collection{S} end

Base.eltype(::Type{<:Collection{S}}) where {S} = S
Base.copy(collection::Collection) = typeof(collection)(copy(collection.data))

function Base.get(default, collection::Collection{T}, key) where {T}
  idx = findfirst(x -> matches(key, x), collection.data)
  isnothing(idx) && return default()
  collection.data[idx]::T
end
Base.get(default, collection::Collection, spec::Spec) = get(default, collection, key(spec))
Base.get(collection::Collection, x, default) = get(Returns(default), collection, x)
Base.getindex(collection::Collection, x) = get(() -> throw(KeyError(x)), collection, x)
Base.getindex(collection::Collection, x::Int64) = collection.data[x]
Base.getindex(collection::Collection, x::AbstractArray) = collection.data[x]
Base.haskey(collection::Collection, x) = !isnothing(get(collection, x, nothing))
Base.union!(x::T, y::T) where {T <: Collection} = T(union!(x.data, y.data))

Base.filter(f::F, collection::Collection) where {F} = typeof(collection)(filter(f, collection.data))
Base.filter!(f::F, collection::Collection) where {F} = typeof(collection)(filter!(f, collection.data))
@forward_methods Collection field = :data Base.keys
@forward_interface Collection field = :data interface = [iteration, indexing] omit = [getindex]

@generated function Base.getproperty(collection::Collection{T}, name::Symbol) where {T}
  ex = quote
    name === :data && return getfield(collection, :data)
  end
  for name in fieldnames(T)
    push!(ex.args, :(name === $(QuoteNode(name)) && return getproperty(collection.data, name)))
  end
  push!(ex.args, :(getfield(collection, name)))
  ex
end

matches(_key, x) = _key == key(x)
data_type(::Type{T}) where {T} = StructVector{T, structvector_fields(T), Int64}

@generated function structvector_fields(::Type{T}) where {T}
  fields = Expr[]
  for (name, t) in zip(fieldnames(T), fieldtypes(T))
    push!(fields, :($name::Vector{$t}))
  end
  Expr(:macrocall, Symbol("@NamedTuple"), nothing, Expr(:braces, fields...))
end
