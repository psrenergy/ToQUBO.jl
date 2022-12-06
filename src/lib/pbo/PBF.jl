import Base: isiterable

using MutableArithmetics
const MA = MutableArithmetics

@doc raw"""
"""
function _parseterm end

_parseterm(::Type{S}, ::Type{T}, x::Any) where {S,T} = error("Invalid term '$(x)'") # fallback
_parseterm(::Type{S}, ::Type{T}, ::Nothing) where {S,T} = (Set{S}(), one(T))
_parseterm(::Type{S}, ::Type{T}, x::T) where {S,T} = (Set{S}(), x)
_parseterm(::Type{S}, ::Type{T}, x::S) where {S,T} = (Set{S}([x]), one(T))
_parseterm(::Type{S}, ::Type{T}, x::Union{Vector{S},Set{S}}) where {S,T} =
    (Set{S}(x), one(T))
_parseterm(::Type{S}, ::Type{T}, x::Pair{Nothing,T}) where {S,T} = (Set{S}(), last(x))
_parseterm(::Type{S}, ::Type{T}, x::Tuple{Nothing,T}) where {S,T} = (Set{S}(), last(x))
_parseterm(::Type{S}, ::Type{T}, x::Union{Pair{S,T},Tuple{S,T}}) where {S,T} =
    (Set{S}([first(x)]), last(x))
_parseterm(::Type{S}, ::Type{T}, x::Pair{<:Union{Vector{S},Set{S}},T}) where {S,T} =
    (Set{S}(first(x)), last(x))
_parseterm(::Type{S}, ::Type{T}, x::Tuple{<:Union{Vector{S},Set{S}},T}) where {S,T} =
    (Set{S}(first(x)), last(x))

@doc raw"""
A Pseudo-Boolean Function ``f \in \mathscr{F}`` over some field ``\mathbb{T}`` takes the form

```math
f(\mathbf{x}) = \sum_{\omega \in \Omega\left[f\right]} c_\omega \prod_{j \in \omega} \mathbb{x}_j
```

where each ``\Omega\left[{f}\right]`` is the multi-linear representation of ``f`` as a set of terms. Each term is given by a unique set of indices ``\omega \subseteq \mathbb{S}`` related to some coefficient ``c_\omega \in \mathbb{T}``. We say that ``\omega \in \Omega\left[{f}\right] \iff c_\omega \neq 0``.
Variables ``\mathbf{x}_i`` are indeed boolean, thus ``f : \mathbb{B}^{n} \to \mathbb{T}``.

## References
 * [1] Endre Boros, Peter L. Hammer, Pseudo-Boolean optimization, Discrete Applied Mathematics, 2002 [{doi}](https://doi.org/10.1016/S0166-218X(01)00341-9)
"""
struct PseudoBooleanFunction{S,T}
    Ω::Dict{Set{S},T}

    function PseudoBooleanFunction{S,T}(Ω::Dict{<:Union{Set{S},Nothing},T}) where {S,T}
        new{S,T}(
            Dict{Set{S},T}(isnothing(ω) ? Set{S}() : ω => c for (ω, c) in Ω if !iszero(c)),
        )
    end

    function PseudoBooleanFunction{S,T}(v::Vector) where {S,T}
        Ω = Dict{Set{S},T}()

        for x in v
            ω, a = _parseterm(S, T, x)
            Ω[ω] = get(Ω, ω, zero(T)) + a
        end

        PseudoBooleanFunction{S,T}(Ω)
    end

    function PseudoBooleanFunction{S,T}(x::Base.Generator) where {S,T}
        PseudoBooleanFunction{S,T}(collect(x))
    end

    function PseudoBooleanFunction{S,T}(x::Vararg{Any}) where {S,T}
        PseudoBooleanFunction{S,T}(collect(x))
    end

    function PseudoBooleanFunction{S,T}() where {S,T}
        new{S,T}(Dict{Set{S},T}())
    end
end

# -*- Alias -*-
const PBF{S,T} = PseudoBooleanFunction{S,T}

#-*- Copy -*-
function Base.copy!(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    sizehint!(f, length(g))
    copy!(f.Ω, g.Ω)

    return f
end

function Base.copy(f::PBF{S,T}) where {S,T}
    return copy!(PBF{S,T}(), f)
end

# -*- Iterator & Length -*-
Base.keys(f::PBF)                = keys(f.Ω)
Base.values(f::PBF)              = values(f.Ω)
Base.length(f::PBF)              = length(f.Ω)
Base.empty!(f::PBF)              = empty!(f.Ω)
Base.isempty(f::PBF)             = isempty(f.Ω)
Base.iterate(f::PBF)             = iterate(f.Ω)
Base.iterate(f::PBF, i::Integer) = iterate(f.Ω, i)

Base.haskey(f::PBF{S}, k::Set{S}) where {S} = haskey(f.Ω, k)
Base.haskey(f::PBF{S}, k::S) where {S}      = haskey(f.Ω, Set{S}([k]))
Base.haskey(f::PBF{S}, ::Nothing) where {S} = haskey(f.Ω, Set{S}())

# -*- Indexing: Get -*-
Base.getindex(f::PBF{S,T}, ω::Set{S}) where {S,T} = get(f.Ω, ω, zero(T))
Base.getindex(f::PBF{S}, η::Vector{S}) where {S}  = getindex(f, Set{S}(η))
Base.getindex(f::PBF{S}, ξ::S...) where {S}       = getindex(f, Set{S}(ξ))
Base.getindex(f::PBF{S}, ::Nothing) where {S}     = getindex(f, Set{S}())

# -*- Indexing: Set -*-
function Base.setindex!(f::PBF{S,T}, c::T, ω::Set{S}) where {S,T}
    if !iszero(c)
        setindex!(f.Ω, c, ω)
    elseif haskey(f.Ω, ω)
        delete!(f.Ω, ω)
    end

    return c
end

Base.setindex!(f::PBF{S,T}, c::T, η::Vector{S}) where {S,T} = setindex!(f, c, Set{S}(η))
Base.setindex!(f::PBF{S,T}, c::T, ξ::S...) where {S,T}      = setindex!(f, c, Set{S}(ξ))
Base.setindex!(f::PBF{S,T}, c::T, ::Nothing) where {S,T}    = setindex!(f, c, Set{S}())

# -*- Properties -*-
Base.size(f::PBF{S,T}) where {S,T} = (length(f),)

function Base.sizehint!(f::PBF, n::Integer)
    sizehint!(f.Ω, n)

    return f
end

# -*- Comparison: (==, !=, ===, !==) -*- #
Base.:(==)(f::PBF{S,T}, g::PBF{S,T}) where {S,T} = f.Ω == g.Ω
Base.:(==)(f::PBF{S,T}, a::T) where {S,T}        = isscalar(f) && (f[nothing] == a)
Base.:(!=)(f::PBF{S,T}, g::PBF{S,T}) where {S,T} = f.Ω != g.Ω
Base.:(!=)(f::PBF{S,T}, a::T) where {S,T}        = !isscalar(f) || (f[nothing] != a)

function Base.isapprox(f::PBF{S,T}, g::PBF{S,T}; kw...) where {S,T}
    return (length(f) == length(g)) &&
           all(haskey(g, ω) && isapprox(g[ω], f[ω]; kw...) for ω in keys(f))
end

function Base.isapprox(f::PBF{S,T}, a::T; kw...) where {S,T}
    return isscalar(f) && isapprox(f[nothing], a; kw...)
end

function isscalar(f::PBF{S}) where {S}
    return isempty(f) || (length(f) == 1 && haskey(f, nothing))
end

Base.zero(::Type{PBF{S,T}}) where {S,T}    = PBF{S,T}()
Base.iszero(f::PBF)                        = isempty(f)
Base.one(::Type{PBF{S,T}}) where {S,T}     = PBF{S,T}(one(T))
Base.isone(f::PBF)                         = isscalar(f) && isone(f[nothing])
Base.round(f::PBF{S,T}; kw...) where {S,T} = PBF{S,T}(ω => round(c; kw...) for (ω, c) in f)

# -*- Arithmetic: (+) -*-
function Base.:(+)(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    h = copy(f)

    for (ω, c) in g
        h[ω] += c
    end

    return h
end

function Base.:(+)(f::PBF{S,T}, c::T) where {S,T}
    if iszero(c)
        copy(f)
    else
        g = copy(f)

        g[nothing] += c

        return g
    end
end

Base.:(+)(f::PBF{S,T}, c) where {S,T} = +(f, convert(T, c))
Base.:(+)(c, f::PBF)                  = +(f, c)

# -*- Arithmetic: (-) -*-
function Base.:(-)(f::PBF{S,T}) where {S,T}
    return PBF{S,T}(Dict{Set{S},T}(ω => -c for (ω, c) in f))
end

function Base.:(-)(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    h = copy(f)

    for (ω, c) in g
        h[ω] -= c
    end

    return h
end

function Base.:(-)(f::PBF{S,T}, c::T) where {S,T}
    if iszero(c)
        copy(f)
    else
        g = copy(f)

        g[nothing] -= c

        return g
    end
end

function Base.:(-)(c::T, f::PBF{S,T}) where {S,T}
    g = -f

    if !iszero(c)
        g[nothing] += c
    end

    return g
end

Base.:(-)(c, f::PBF{S,T}) where {S,T} = -(convert(T, c), f)
Base.:(-)(f::PBF{S,T}, c) where {S,T} = -(f, convert(T, c))

# -*- Arithmetic: (*) -*-
function Base.:(*)(f::PBF{S,T}, g::PBF{S,T}) where {S,T}
    if iszero(f) || iszero(g)
        return zero(PBF{S,T})
    else
        h = PBF{S,T}()
        
        sizehint!(h, length(f) * length(g))

        for (ωᵢ, cᵢ) in f, (ωⱼ, cⱼ) in g
            h[union(ωᵢ, ωⱼ)] += cᵢ * cⱼ
        end

        return h
    end
end

function Base.:(*)(f::PBF{S,T}, a::T) where {S,T}
    if iszero(a)
        return PBF{S,T}()
    else
        return PBF{S,T}(ω => c * a for (ω, c) ∈ f)
    end
end

Base.:(*)(f::PBF{S,T}, a) where {S,T} = *(f, convert(T, a))
Base.:(*)(a, f::PBF)                  = *(f, a)

# -*- Arithmetic: (/) -*-
function Base.:(/)(f::PBF{S,T}, a::T) where {S,T}
    if iszero(a)
        throw(DivideError())
    else
        return PBF{S,T}(Dict(ω => c / a for (ω, c) in f))
    end
end

Base.:(/)(f::PBF{S,T}, a) where {S,T} = /(f, convert(T, a))

# -*- Arithmetic: (^) -*-
function Base.:(^)(f::PBF{S,T}, n::Integer) where {S,T}
    if n < 0
        throw(DivideError())
    elseif n == 0
        return one(PBF{S,T})
    elseif n == 1
        return f
    elseif n == 2
        return f * f
    else
        g = f * f

        if iseven(n)
            return g^(n ÷ 2)
        else
            return g^(n ÷ 2) * f
        end
    end
end

# -*- Arithmetic: Evaluation -*-
function (f::PBF{S,T})(x::Dict{S,U}) where {S,T,U<:Integer}
    g = PBF{S,T}()

    for (ω, c) in f
        η = Set{S}()

        for j in ω
            if haskey(x, j)
                if iszero(x[j])
                    c = zero(T)
                    break
                end
            else
                push!(η, j)
            end
        end

        g[η] += c
    end

    return g
end

function (f::PBF{S,T})(η::Set{S}) where {S,T}
    return sum(c for (ω, c) in f if ω ⊆ η; init = zero(T))
end

function (f::PBF{S})(x::Pair{S,U}...) where {S,U<:Integer}
    return f(Dict{S,U}(x...))
end

function (f::PBF{S})() where {S}
    return f(Dict{S,Int}())
end

# -*- Type conversion -*-
function Base.convert(U::Type{<:T}, f::PBF{<:Any,T}) where {T}
    if isempty(f)
        return zero(U)
    elseif degree(f) == 0
        return convert(U, f[nothing])
    else
        error("Can't convert non-constant Pseudo-boolean Function to scalar type '$U'")
    end
end


# -*- MA Mutable Arithmetics -*-

MA.mutability(::Type{<:PBF{S,T}}) where {S,T} = MA.IsMutable()


# -*- MA Mutable Copy: -*-
function MA.mutable_copy(f::PBF{S,T}) where{S,T}
    f_copy = PBO.PBF{S,T}()
    for (ω,c) in f
        f_copy[ω] = MA.copy_if_mutable(f[ω])
    end
    return f_copy
end

# -*- MA isequal_canonical: -*-
function MA.isequal_canonical(
    f::PBF{S,T},
    g::PBF{S,T}
    ) where {S,T}
    
    return f == g
    
end


# -*- MA Arithmetic: zero,one -*-
function MA.operate!(
    ::typeof(zero),
    f::PBF{S,T}
    ) where {S,T}

    empty!(f)
    
    return f
end

function MA.operate!(
    ::typeof(one),
    f::PBF{S,T}
    ) where {S,T}

    empty!(f)
    f[nothing] = one(T)

    return f
end


# -*- MA Arithmetic: (+) -*-

function MA.operate!(
    ::typeof(+),
    f::PBF{S,T}, 
    g::PBF{S,T}
    ) where {S,T}

    for(ω, c) in g
        f[ω] += c
    end
    
    return f
end

function MA.operate!(
    ::typeof(+),
    f::PBF{<:Any,T}, 
    c::T
    ) where {T}
    if iszero(c)
        return f
    end
    
    f[nothing] += c

    return f
end

# -*- MA Arithmetic: (-) -*-


function MA.operate!(
    ::typeof(-),
    f::PBF{S,T}
    ) where {S,T}

    for(ω, c) in f
        f[ω] = -c 
    end
    
    return f
end

function MA.operate!(
    ::typeof(-),
    f::PBF{S,T}, 
    g::PBF{S,T}
    ) where {S,T}

    for(ω, c) in g
        f[ω] -= c
    end

    return f
end


function MA.operate!(
    ::typeof(-),
    f::PBF{<:Any,T}, 
    c::T
    ) where {T}
    if iszero(c)
        return f
    end
    
    f[nothing] -= c

    return f
end

# -*- MA Arithmetic: (*) -*-

function MA.operate!(
    ::typeof(*),
    f::PBF{S,T}, 
    g::PBF{S,T}
    ) where {S,T}

    h = PBF{S,T}()

    if isempty(f) || isempty(g)
        return h
    else
        for (ωᵢ, cᵢ) in f, (ωⱼ, cⱼ) in g
            h[union(ωᵢ, ωⱼ)] += cᵢ * cⱼ
        end

        return h
    end

end

function MA.operate!(
    ::typeof(*),
    f::PBF{S,T}, 
    a::T
    ) where {S,T}

    if iszero(a)
        empty!(f)
    else
        for(ω, c) in f
            f[ω] = c*a
        end
    end

    return f
end

# -*- MA Arithmetic: (add_mul) -*-
function MA.operate!(
    ::typeof(add_mul),
    f::PBF{S,T},
    m::T,
    g::PBF{S,T}
    ) where {S,T}

    for(ω, c) in g
        f[ω] += m*c
    end
    return f
    
end

# -*- MA Arithmetic: (sub_mul) -*-
function MA.operate!(
    ::typeof(sub_mul),
    f::PBF{S,T},
    m::T,
    g::PBF{S,T}
    ) where {S,T}

    for(ω, c) in g
        f[ω] -= m*c
    end
    return f
    
end

# -*- MA Arithmetic: (/) -*-

function MA.operate!(
    ::typeof(/),
    f::PBF{S,T}, 
    a::T
    ) where {S,T}

    if iszero(a)
        throw(DivideError())
    else
        for(ω, c) in f
            f[ω] = c / a
        end
    end

    return f
end

# -*- MA Arithmetic: (^) -*-
function MA.operate!(
    ::typeof(^),
    f::PBF{S,T}, 
    n::Integer
    ) where {S,T}

    if n < 0
        throw(DivideError())
    elseif n == 0
        return MA.operate!(one, f)
    elseif n == 1
        return f
    elseif n == 2
        for (ω,c) in f
            f[ω] = c*c
        end
    else    
        for (ω,c) in f
            f[ω] = c*c
        end

        if iseven(n)
            return f^(n ÷ 2)
        else
            return f^(n ÷ 2) * f
        end
    end
end


function MA.operate_to!(
    output::PBF{S,T},
    op::Union{typeof(+),typeof(-)},
    f::PBF{S,T},
    g::PBF{S,T},
) where {S,T}
    empty!(output)
    MA.operate!(+, output, f)
    MA.operate!(op, output, g)
    return output
end



# -*- MA Arithmetic: Evaluation -*-



# -*- MA Type conversion -*-

