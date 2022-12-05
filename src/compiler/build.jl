using MutableArithmetics
const MA = MutableArithmetics

function toqubo_hamiltonian!(model::VirtualQUBOModel{T}, ::AbstractArchitecture) where {T}
    copy!(model.H, model.f)

    for (ci, g) in model.g
        ρ = model.ρ[ci]

        for (ω, c) in g
            model.H[ω] += ρ * c
        end
    end

    for (vi, h) in model.h
        θ = model.θ[vi]

        for (ω, c) in h
            model.H[ω] += θ * c
        end
    end

    return nothing
end

function toqubo_quadratize!(model::VirtualQUBOModel{T}, ::AbstractArchitecture) where {T}
    Q = PBO.quadratize(model.H) do n::Integer
        m = MOI.get(model, TargetModel())
        w = MOI.add_variables(m, n)

        MOI.add_constraint.(m, w, MOI.ZeroOne())

        return w
    end

    copy!(model.H, Q)

    return nothing
end

function toqubo_output!(model::VirtualQUBOModel{T}, ::AbstractArchitecture) where {T}
    Q = SQT{T}[]
    a = SAT{T}[]
    b = zero(T)

    for (ω, c) in model.H
        if isempty(ω)
            b += c
        elseif length(ω) == 1
            push!(a, SAT{T}(c, ω...))
        elseif length(ω) == 2
            push!(Q, SQT{T}(c, ω...))
        else
            # NOTE: This should never happen in production.
            # During implementation of new quadratization and constraint reformulation methods
            # higher degree terms might be introduced by mistake. That's why it's important to 
            # have this condition here.
            throw(QUBOError("Quadratization failed"))
        end
    end

    MOI.set(
        MOI.get(model, TargetModel()),
        MOI.ObjectiveFunction{SQF{T}}(),
        SQF{T}(Q, a, b),
    )

    return nothing
end

function toqubo_build!(model::VirtualQUBOModel{T}, arch::AbstractArchitecture) where {T}
    # -*- Assemble Objective Function -*-
    toqubo_hamiltonian!(model, arch)

    # -*- Quadratization Step -*-
    toqubo_quadratize!(model, arch)

    # -*- Write to MathOptInterface -*-
    toqubo_output!(model, arch)

    return nothing
end