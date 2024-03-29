@doc raw"""
    Unary{T}()

## Integer
Let ``x \in [a, b] \subset \mathbb{Z}``, ``n = b - a`` and ``\mathbf{y} \in \mathbb{B}^{n}``.

```math
\xi{[a, b]}(\mathbf{y}) = a + \sum_{j = 1}^{b - a} y_{j}
```

## Real
Given ``n \in \mathbb{N}`` for ``x \in [a, b] \subset \mathbb{R}``,

```math
\xi{[a, b]}(\mathbf{y}) = a + \frac{b - a}{n} \sum_{j = 1}^{n} y_{j}
```

### Representation error

Given ``\tau > 0``, for the expected encoding error to be less than or equal to ``\tau``, at least

```math
n \ge 1 + \frac{b - a}{4 \tau}
```

binary variables become necessary.
"""
struct Unary{T} <: IntervalVariableEncodingMethod end

Unary() = Unary{Float64}()

@doc raw"""
    encode(var::Function, ::Unary{T}, S::Tuple{T,T}) where {T}

Given ``S = [a, b] \subset \mathbb{Z}``, ``a < b``, let ``n = b - a`` and ``\mathbf{y} \in \mathbb{B}^{n}``.

```math
\xi{[a, b]}(\mathbf{y}) = a + \sum_{j = 1}^{b - a} y_{j}
```
"""
function encode(var::Function, e::Unary{T}, S::Tuple{T,T}; tol::Union{T,Nothing} = nothing) where {T}
    !isnothing(tol) && return encode(var, e, S, nothing; tol)

    a, b = integer_interval(S)

    if a == b
        return (VI[], PBO.PBF{VI,T}(a), nothing)
    end

    N = trunc(Int, b - a)

    y = var(N)::Vector{VI}
    ξ = PBO.PBF{VI,T}([a; [y[i] => one(T) for i = 1:N]])

    return (y, ξ, nothing) # No penalty function
end

function encoding_bits(::Unary{T}, S::Tuple{T,T}, tol::T) where {T}
    @assert tol > zero(T)

    a, b = S

    return ceil(Int, (1 + abs(b - a) / 4tol))
end

# Real
function encode(
    var::Function,
    e::Unary{T},
    S::Tuple{T,T},
    n::Union{Integer,Nothing};
    tol::Union{T,Nothing} = nothing,
) where {T}
    @assert !(isnothing(tol) && isnothing(n))

    if isnothing(n)
        n = encoding_bits(e, S, tol)
    end

    @assert n >= 0

    a, b = S

    if n == 0
        y = Vector{VI}()
        ξ = PBO.PBF{VI,T}((a + b) / 2)
    else
        y = var(n)::Vector{VI}
        ξ = PBO.PBF{VI,T}([a; [y[i] => (b - a) / n for i = 1:n]])
    end

    return (y, ξ, nothing) # No penalty function
end
