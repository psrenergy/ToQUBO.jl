# -*- Virtual Variable Encoding -*-
abstract type Encoding end

@doc raw"""
    encode!(model::VirtualModel{T}, v::VirtualVariable{T}) where {T}

Maps newly created virtual variable `v` within the virtual model structure. It follows these steps:
 
 1. Maps `v`'s source to it in the model's `source` mapping.
 2. For every one of `v`'s targets, maps it to itself and adds a binary constraint to it.
 2. Adds `v` to the end of the model's `varvec`.  
""" function encode! end

@doc raw"""
# Variable Expansion methods:
    - Linear
    - Unary
    - Binary
    - One Hot
    - Domain Wall

# References:
 * [1] Chancellor, N. (2019). Domain wall encoding of discrete variables for quantum annealing and QAOA. _Quantum Science and Technology_, _4_(4), 045004. [{doi}](https://doi.org/10.1088/2058-9565/ab33c2)
"""
struct VirtualVariable{T}
    e::Encoding
    x::Union{VI,Nothing}             # Source variable (if there is one)
    y::Vector{VI}                    # Target variables
    ξ::PBO.PBF{VI,T}                 # Expansion function
    h::Union{PBO.PBF{VI,T},Nothing}  # Penalty function (i.e. ‖gᵢ(x)‖ₛ for g(i) ∈ S)

    function VirtualVariable{T}(
        e::Encoding,
        x::Union{VI,Nothing},
        y::Vector{VI},
        ξ::PBO.PBF{VI,T},
        h::Union{PBO.PBF{VI,T},Nothing},
    ) where {T}
        return new{T}(e, x, y, ξ, h)
    end
end

const VV{T} = VirtualVariable{T}

encoding(v::VirtualVariable)  = v.e
source(v::VirtualVariable)    = v.x
target(v::VirtualVariable)    = v.y
is_aux(v::VirtualVariable)    = isnothing(source(v))
expansion(v::VirtualVariable) = v.ξ
penaltyfn(v::VirtualVariable) = v.h

@doc raw"""
    VirtualModel{T}(optimizer::Union{Nothing, Type{<:MOI.AbstractOptimizer}} = nothing) where {T}

This Virtual Model links the final QUBO formulation to the original one, allowing variable value retrieving and other features.
"""
struct VirtualModel{T} <: MOI.AbstractOptimizer
    # -*- Underlying Optimizer -*- #
    optimizer::Union{MOI.AbstractOptimizer,Nothing}

    # -*- MathOptInterface Bridges -*- #
    bridge_model::MOIB.LazyBridgeOptimizer{PreQUBOModel{T}}

    # -*- Virtual Model Interface -*- #
    source_model::PreQUBOModel{T}
    target_model::QUBOModel{T}
    variables::Vector{VV{T}}
    source::Dict{VI,VV{T}}
    target::Dict{VI,VV{T}}

    # -*- PBO/PBF IR -*- #
    f::PBO.PBF{VI,T}          # Objective Function
    g::Dict{CI,PBO.PBF{VI,T}} # Constraint Functions
    h::Dict{VI,PBO.PBF{VI,T}} # Variable Functions
    ρ::Dict{CI,T}             # Constraint Penalties
    θ::Dict{VI,T}             # Variable Penalties
    H::PBO.PBF{VI,T}          # Final Hamiltonian

    # -*- Settings -*-
    compiler_settings::Dict{Symbol,Any}
    variable_settings::Dict{Symbol,Dict{VI,Any}}
    constraint_settings::Dict{Symbol,Dict{CI,Any}}

    function VirtualModel{T}(
        constructor::Union{Type{O},Function};
        kws...,
    ) where {T,O<:MOI.AbstractOptimizer}
        optimizer = constructor()

        return VirtualModel{T}(optimizer; kws...)
    end

    function VirtualModel{T}(
        optimizer::Union{O,Nothing} = nothing;
        kws...,
    ) where {T,O<:MOI.AbstractOptimizer}
        source_model = PreQUBOModel{T}()
        target_model = QUBOModel{T}()
        bridge_model = MOIB.full_bridge_optimizer(source_model, T)

        new{T}(
            # -*- Underlying Optimizer -*- #
            optimizer,

            # -*- MathOptInterface Bridges -*- #
            bridge_model,

            # -*- Virtual Model Interface -*-
            source_model,
            target_model,
            Vector{VV{T}}(),
            Dict{VI,VV{T}}(),
            Dict{VI,VV{T}}(),

            # -*- PBO/PBF IR -*-
            PBO.PBF{VI,T}(),          # Objective Function
            Dict{CI,PBO.PBF{VI,T}}(), # Constraint Functions
            Dict{VI,PBO.PBF{VI,T}}(), # Variable Functions
            Dict{CI,T}(),             # Constraint Penalties
            Dict{VI,T}(),             # Variable Penalties
            PBO.PBF{VI,T}(),          # Final Hamiltonian

            # -*- Settings -*-
            Dict{Symbol,Any}(),
            Dict{Symbol,Dict{VI,Any}}(),
            Dict{Symbol,Dict{CI,Any}}(),
        )
    end

end

VirtualModel(args...; kws...) = VirtualModel{Float64}(args...; kws...)

function encode!(model::VirtualModel{T}, v::VV{T}) where {T}
    if !is_aux(v)
        let x = source(v)
            model.source[x] = v
        end
    end

    for y in target(v)
        MOI.add_constraint(model.target_model, y, MOI.ZeroOne())
        model.target[y] = v
    end

    # Add variable to collection
    push!(model.variables, v)

    return v
end

@doc raw"""
    LinearEncoding <: Encoding

Every linear encoding ``\xi`` is of the form
```math
\xi(\mathbf{y}) = \alpha + \sum_{i = 1}^{n} \gamma_{i} y_{i}
```

""" abstract type LinearEncoding <: Encoding end

function VirtualVariable{T}(
    e::LinearEncoding,
    x::Union{VI,Nothing},
    y::Vector{VI},
    γ::Vector{T},
    α::T = zero(T),
) where {T}
    @assert (n = length(y)) == length(γ)

    ξ = α + PBO.PBF{VI,T}(y[i] => γ[i] for i = 1:n)

    return VirtualVariable{T}(e, x, y, ξ, nothing)
end

function encode!(
    e::LinearEncoding,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    γ::Vector{T},
    α::T = zero(T),
) where {T}
    n = length(γ)
    y = MOI.add_variables(model.target_model, n)
    v = VirtualVariable{T}(e, x, y, γ, α)

    return encode!(model, v)
end

@doc raw"""
""" struct Mirror <: LinearEncoding end

function encode!(e::Mirror, model::VirtualModel{T}, x::Union{VI,Nothing}) where {T}
    return encode!(e, model, x, ones(T, 1))
end

@doc raw"""
""" struct Linear <: LinearEncoding end

function encode!(
    e::Linear,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    Γ::Function,
    n::Integer,
) where {T}
    γ = T[Γ(i) for i = 1:n]

    return encode!(e, model, x, γ, zero(T))
end

@doc raw"""
""" struct Unary <: LinearEncoding end

function encode!(
    e::Unary,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
) where {T}
    α, β = if a < b
        ceil(a), floor(b)
    else
        ceil(b), floor(a)
    end

    # assumes: β - α > 0
    M = trunc(Int, β - α)
    γ = ones(T, M)

    return encode!(e, model, x, γ, α)
end

function encode!(
    e::Unary,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    n::Integer,
) where {T}
    Γ = (b - a) / n
    γ = Γ * ones(T, n)

    return encode!(e, model, x, γ, a)
end

function encode!(
    e::Unary,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    τ::T,
) where {T}
    n = ceil(Int, (1 + abs(b - a) / 4τ))

    return encode!(e, model, x, a, b, n)
end

@doc raw"""
Binary Expansion within the closed interval ``[\alpha, \beta]``.

For a given variable ``x \in [\alpha, \beta]`` we approximate it by

```math    
x \approx \alpha + \frac{(\beta - \alpha)}{2^{n} - 1} \sum_{i=0}^{n-1} {2^{i}\, y_i}
```

where ``n`` is the number of bits and ``y_i \in \mathbb{B}``.
""" struct Binary <: LinearEncoding end

function encode!(
    e::Binary,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
) where {T}
    α, β = if a < b
        ceil(a), floor(b)
    else
        ceil(b), floor(a)
    end

    # assumes: β - α > 0
    M = trunc(Int, β - α)
    N = ceil(Int, log2(M + 1))

    γ = if N == 0
        T[M+1/2]
    else
        T[[2^i for i = 0:N-2]; [M - 2^(N - 1) + 1]]
    end

    return encode!(e, model, x, γ, α)
end

function encode!(
    e::Binary,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    n::Integer,
) where {T}
    Γ = (b - a) / (2^n - 1)
    γ = Γ * 2 .^ collect(T, 0:n-1)

    return encode!(e, model, x, γ, a)
end

function encode!(
    e::Binary,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    τ::T,
) where {T}
    n = ceil(Int, log2(1 + abs(b - a) / 4τ))

    return encode!(e, model, x, a, b, n)
end

@doc raw"""
""" struct Arithmetic <: LinearEncoding end

function encode!(
    e::Arithmetic,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
) where {T}
    α, β = if a < b
        ceil(a), floor(b)
    else
        ceil(b), floor(a)
    end

    # assumes: β - α > 0
    M = trunc(Int, β - α)
    N = ceil(Int, (sqrt(1 + 8M) - 1) / 2)

    γ = T[[i for i = 1:N-1]; [M - N * (N - 1) / 2]]

    return encode!(e, model, x, γ, α)
end

function encode!(
    e::Arithmetic,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    n::Integer,
) where {T}
    Γ = 2 * (b - a) / (n * (n + 1))
    γ = Γ * collect(1:n)

    return encode!(e, model, x, γ, a)
end

function encode!(
    e::Arithmetic,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    τ::T,
) where {T}
    n = ceil(Int, (1 + sqrt(3 + (b - a) / 2τ)) / 2)

    return encode!(e, model, x, a, b, n)
end

@doc raw"""
""" struct OneHot <: LinearEncoding end

function VirtualVariable{T}(
    e::OneHot,
    x::Union{VI,Nothing},
    y::Vector{VI},
    γ::Vector{T},
    α::T = zero(T),
) where {T}
    @assert (n = length(y)) == length(γ)

    ξ = α + PBO.PBF{VI,T}(y[i] => γ[i] for i = 1:n)
    h = (one(T) - PBO.PBF{VI,T}(y))^2

    return VirtualVariable{T}(e, x, y, ξ, h)
end

function encode!(
    e::OneHot,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
) where {T}
    α, β = if a < b
        ceil(a), floor(b)
    else
        ceil(b), floor(a)
    end

    # assumes: β - α > 0
    γ = collect(T, α:β)

    return encode!(e, model, x, γ)
end

function encode!(
    e::OneHot,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    n::Integer,
) where {T}
    Γ = (b - a) / (n - 1)
    γ = a .+ Γ * collect(T, 0:n-1)

    return encode!(e, model, x, γ)
end

function encode!(
    e::OneHot,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    τ::T,
) where {T}
    n = ceil(Int, (1 + abs(b - a) / 4τ))

    return encode!(e, model, x, a, b, n)
end

abstract type SequentialEncoding <: Encoding end

function encode!(
    e::SequentialEncoding,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    γ::Vector{T},
    α::T = zero(T),
) where {T}
    n = length(γ)
    y = MOI.add_variables(model.target_model, n - 1)
    v = VirtualVariable{T}(e, x, y, γ, α)

    return encode!(model, v)
end

struct DomainWall <: SequentialEncoding end

function VirtualVariable{T}(
    e::DomainWall,
    x::Union{VI,Nothing},
    y::Vector{VI},
    γ::Vector{T},
    α::T = zero(T),
) where {T}
    @assert (n = length(y)) == length(γ) - 1

    ξ = α + PBO.PBF{VI,T}(y[i] => (γ[i] - γ[i+1]) for i = 1:n)
    h = 2 * (PBO.PBF{VI,T}(y[2:n]) - PBO.PBF{VI,T}([Set{VI}([y[i], y[i-1]]) for i = 2:n]))

    return VirtualVariable{T}(e, x, y, ξ, h)
end

function encode!(
    e::DomainWall,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
) where {T}
    α, β = if a < b
        ceil(a), floor(b)
    else
        ceil(b), floor(a)
    end

    # assumes: β - α > 0
    M = trunc(Int, β - α)
    γ = α .+ collect(T, 0:M)

    return encode!(e, model, x, γ)
end

function encode!(
    e::DomainWall,
    model::VirtualModel{T},
    x::Union{VI,Nothing},
    a::T,
    b::T,
    n::Integer,
) where {T}
    Γ = (b - a) / (n - 1)
    γ = a .+ Γ * collect(T, 0:n-1)

    return encode!(e, model, x, γ)
end
