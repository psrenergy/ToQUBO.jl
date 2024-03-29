function MOI.get(model::Virtual.Model, raw_attr::MOI.RawOptimizerAttribute)
    if !isnothing(model.optimizer) && MOI.supports(model.optimizer, raw_attr)
        return MOI.get(model.optimizer, raw_attr)
    else
        # Error if no underlying optimizer is present
        MOI.get_fallback(model, raw_attr)
    end
end

function MOI.set(model::Virtual.Model, raw_attr::MOI.RawOptimizerAttribute, args...)
    if !isnothing(model.optimizer) && MOI.supports(model.optimizer, raw_attr)
        MOI.set(model.optimizer, raw_attr, args...)
    else
        # Error if no underlying optimizer is present
        MOI.throw_set_error_fallback(model, raw_attr, args...)
    end

    return nothing
end

function MOI.supports(model::Virtual.Model, raw_attr::MOI.RawOptimizerAttribute)
    if !isnothing(model.optimizer)
        return MOI.supports(model.optimizer, raw_attr)
    else
        # ToQUBO.Optimizer doesn't support any raw attributes
        return false
    end
end

function MOI.get(model::Virtual.Model, attr::MOI.AbstractOptimizerAttribute)
    if !isnothing(model.optimizer) && MOI.supports(model.optimizer, attr)
        return MOI.get(model.optimizer, attr)
    else
        return MOI.get(model.source_model, attr)
    end
end

function MOI.set(model::Virtual.Model, attr::MOI.AbstractOptimizerAttribute, args...)
    if !isnothing(model.optimizer) && MOI.supports(model.optimizer, attr)
        MOI.set(model.optimizer, attr, args...)
    else
        MOI.set(model.source_model, attr, args...)
    end

    return nothing
end

function MOI.supports(model::Virtual.Model, attr::MOI.AbstractOptimizerAttribute)
    if !isnothing(model.optimizer)
        return MOI.supports(model.optimizer, attr)
    else
        return MOI.supports(model.source_model, attr)
    end
end

function MOI.get(
    model::Virtual.Model,
    attr::MOI.SolveTimeSec,
)
    if !isnothing(model.optimizer)
        return MOI.get(model.optimizer, attr)
    else
        return nothing
    end
end

function MOI.supports(
    model::Virtual.Model,
    attr::MOI.SolveTimeSec,
)
    if !isnothing(model.optimizer)
        return MOI.supports(model.optimizer, attr)
    else
        return false
    end
end

function MOI.get(
    model::Virtual.Model,
    attr::MOI.RawStatusString,
)
    if !isnothing(model.optimizer) && MOI.supports(model.optimizer, attr)
        return MOI.get(model.optimizer, attr)
    else
        return get(model.moi_settings, :raw_status_string, "")
    end
end

function MOI.set(
    model::Virtual.Model,
    ::MOI.RawStatusString,
    value::AbstractString,
)
    model.moi_settings[:raw_status_string] = String(value)
    
    return nothing
end

function MOI.supports(::Virtual.Model, ::MOI.RawStatusString)
    return true
end

function MOI.get(model::Virtual.Model, attr::MOI.TerminationStatus)
    if !isnothing(model.optimizer)
        return MOI.get(model.optimizer, attr)
    else
        return MOI.get(model, Attributes.CompilationStatus())
    end
end

function MOI.supports(::Virtual.Model, ::MOI.TerminationStatus)
    return true
end

function MOI.get(model::Virtual.Model, attr::Union{MOI.PrimalStatus, MOI.DualStatus})
    if !isnothing(model.optimizer)
        return MOI.get(model.optimizer, attr)
    else
        return MOI.NO_SOLUTION
    end
end

function MOI.supports(model::Virtual.Model, attr::Union{MOI.PrimalStatus, MOI.DualStatus})
    if !isnothing(model.optimizer)
        return MOI.supports(model.optimizer, attr)
    else
        return true
    end
end

function MOI.get(model::Virtual.Model, rc::MOI.ResultCount)
    if isnothing(model.optimizer)
        return 0
    else
        return MOI.get(model.optimizer, rc)
    end
end

MOI.supports(::Virtual.Model, ::MOI.ResultCount) = true

function MOI.get(model::Virtual.Model{T}, ov::MOI.ObjectiveValue) where {T}
    if isnothing(model.optimizer)
        return zero(T)
    else
        return MOI.get(model.optimizer, ov)
    end
end

function MOI.get(model::Virtual.Model{T}, vp::MOI.VariablePrimalStart, x::VI) where {T}
    return MOI.get(model.source_model, vp, x)
end

MOI.supports(::Virtual.Model, ::MOI.VariablePrimalStart, ::MOI.VariableIndex) = true

function MOI.get(model::Virtual.Model{T}, vp::MOI.VariablePrimal, x::VI) where {T}
    if !haskey(model.source, x)
        error("Variable '$x' not present in the model")

        return nothing
    end

    if isnothing(model.optimizer)
        return zero(T)
    else
        v = model.source[x]
        s = zero(T)

        for (ω, c) in Virtual.expansion(v)
            for y in ω
                c *= MOI.get(model.optimizer, vp, y)
            end

            s += c
        end

        return s
    end
end

function MOI.get(model::Virtual.Model, rs::MOI.RawSolver)
    if isnothing(model.optimizer)
        return nothing
    else
        return MOI.get(model.optimizer, rs)
    end
end
