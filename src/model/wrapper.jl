function MOI.empty!(model::VirtualQUBOModel)
    # -*- Models -*-
    MOI.empty!(MOI.get(model, VM.SourceModel()))
    MOI.empty!(MOI.get(model, VM.TargetModel()))

    # -*- Virtual Variables -*-
    empty!(MOI.get(model, VM.Variables()))
    empty!(MOI.get(model, VM.Source()))
    empty!(MOI.get(model, VM.Target()))

    # -*- Underlying Optimizer -*-
    isnothing(model.optimizer) || MOI.empty!(model.optimizer)

    # -*- PBF/IR -*-
    empty!(model.f)
    empty!(model.g)
    empty!(model.h)

    # -*- Attributes -*-
    empty!(model.attrs)

    nothing
end

function MOI.optimize!(model::VirtualQUBOModel)
    if isnothing(model.optimizer)
        error("No Optimizer attached")
    end

    MOI.optimize!(model.optimizer, MOI.get(model, VM.TargetModel()))

    (MOIU.identity_index_map(MOI.get(model, VM.SourceModel())), false)
end

function MOI.copy_to(model::VirtualQUBOModel{T}, source::MOI.ModelLike) where {T}
    if !MOI.is_empty(model)
        error("QUBO Model is not empty")
    end

    # -*- Copy to PreQUBOModel + Trigger Bridges -*-
    index_map = MOI.copy_to(
        MOIB.full_bridge_optimizer(MOI.get(model, VM.SourceModel()), T),
        source,
    )

    toqubo!(model)

    index_map
end

# -*- :: Objective Function Support :: -*- #
MOI.supports(
    ::VirtualQUBOModel{T},
    ::MOI.ObjectiveFunction{<:Union{VI,SAF{T},SQF{T}}},
) where {T} = true

# -*- :: Constraint Support :: -*- #
MOI.supports_constraint(
    ::VirtualQUBOModel{T},
    ::Type{<:VI},
    ::Type{<:Union{MOI.ZeroOne,MOI.Integer,MOI.Interval{T}}},
) where {T} = true

MOI.supports_constraint(
    ::VirtualQUBOModel{T},
    ::Type{<:Union{VI,SAF{T},SQF{T}}},
    ::Type{<:Union{MOI.EqualTo{T},MOI.LessThan{T}}},
) where {T} = true

MOI.supports_add_constrained_variable(
    ::VirtualQUBOModel{T},
    ::Type{<:Union{MOI.ZeroOne,MOI.Integer,MOI.Interval{T}}},
) where {T} = true

function MOI.get(
    model::VirtualQUBOModel,
    attr::Union{
        MOI.SolveTimeSec,
        MOI.PrimalStatus,
        MOI.DualStatus,
        MOI.TerminationStatus,
        MOI.RawStatusString,
    }
    )
    if !isnothing(model.optimizer)
        MOI.get(model.optimizer, attr)
    else
        nothing
    end
end

function MOI.set(
    model::VirtualQUBOModel,
    attr::Union{
        MOI.SolveTimeSec,
        MOI.PrimalStatus,
        MOI.DualStatus,
        MOI.TerminationStatus,
        MOI.RawStatusString,
    },
    value::Any,
    )
    MOI.set(model.optimizer, attr, value)
end

MOI.supports(::VirtualQUBOModel, ::MOI.SolveTimeSec) = true

function MOI.get(model::VirtualQUBOModel, rc::MOI.ResultCount)
    if isnothing(model.optimizer)
        0
    else
        MOI.get(model.optimizer, rc)
    end
end

MOI.supports(::VirtualQUBOModel, ::MOI.ResultCount) = true

function MOI.get(model::VirtualQUBOModel{T}, ov::MOI.ObjectiveValue) where {T}
    if isnothing(model.optimizer)
        zero(T)
    else
        MOI.get(model.optimizer, ov)
    end
end

function MOI.get(model::VirtualQUBOModel{T}, vp::MOI.VariablePrimal, x::VI) where {T}
    if isnothing(model.optimizer)
        zero(T)
    else
        s = zero(T)
        for (??, c) in VM.expansion(MOI.get(model, VM.Source(), x))
            for y in ??
                c *= MOI.get(model.optimizer, vp, y)
            end
            s += c
        end
        s
    end
end

MOI.get(::VirtualQUBOModel, ::MOI.SolverName) = "Virtual QUBO Model"
MOI.get(::VirtualQUBOModel, ::MOI.SolverVersion) = v"0.1.0"
MOI.get(model::VirtualQUBOModel, rs::MOI.RawSolver) = MOI.get(model.optimizer, rs)

PBO.showvar(x::VI) = PBO.showvar(x.value)
PBO.varcmp(x::VI, y::VI) = PBO.varcmp(x.value, y.value)

const Optimizer{T} = VirtualQUBOModel{T}