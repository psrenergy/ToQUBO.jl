function toqubo_sense!(model::VirtualQUBOModel, ::AbstractArchitecture)
    MOI.set(model.target_model, MOI.ObjectiveSense(), MOI.get(model, MOI.ObjectiveSense()))

    return nothing
end

function toqubo_objective!(model::VirtualQUBOModel, arch::AbstractArchitecture)
    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    copy!(model.f, toqubo_objective(model, f, arch))

    return nothing
end

function toqubo_objective(
    model::VirtualQUBOModel{T},
    vi::VI,
    ::AbstractArchitecture,
) where {T}
    f = PBO.PBF{VI,T}()

    for (ω, c) in VM.expansion(MOI.get(model, VM.Source(), vi))
        f[ω] += c
    end

    return f
end

function toqubo_objective(
    model::VirtualQUBOModel{T},
    saf::SAF{T},
    ::AbstractArchitecture,
) where {T}
    f = PBO.PBF{VI,T}()

    for t in saf.terms
        c = t.coefficient
        x = t.variable

        for (ω, d) in VM.expansion(MOI.get(model, VM.Source(), x))
            f[ω] += c * d
        end
    end

    f[nothing] += saf.constant

    return f
end

function toqubo_objective(
    model::VirtualQUBOModel{T},
    sqf::SQF{T},
    ::AbstractArchitecture,
) where {T}
    f = PBO.PBF{VI,T}()

    for q in sqf.quadratic_terms
        c = q.coefficient
        xᵢ = q.variable_1
        xⱼ = q.variable_2

        # MOI convetion is to write ScalarQuadraticFunction as
        #     ½ x' Q x + a x + b
        # ∴ every coefficient in the main diagonal is doubled
        if xᵢ === xⱼ
            c /= 2
        end

        for (ωᵢ, dᵢ) in VM.expansion(MOI.get(model, VM.Source(), xᵢ))
            for (ωⱼ, dⱼ) in VM.expansion(MOI.get(model, VM.Source(), xⱼ))
                f[union(ωᵢ, ωⱼ)] += c * dᵢ * dⱼ
            end
        end
    end

    for a in sqf.affine_terms
        c = a.coefficient
        x = a.variable

        for (ω, d) in VM.expansion(MOI.get(model, VM.Source(), x))
            f[ω] += c * d
        end
    end

    f[nothing] += sqf.constant

    return f
end