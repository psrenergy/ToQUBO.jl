function test_logical_sos1()
    @testset "SOS1: 3 variables" begin
        # Problem Data
        n = 3
        A = [
            -1  2  2
             2 -1  2
             2  2 -1
        ]

        # Penalty Choice
        ρ̄ = -16

        # Solution Data
        Q̄ = [
            15 -28 -28 -32
             0  15 -28 -32
             0   0  15 -32
             0   0   0  16
        ]

        ᾱ = 1
        β̄ = -16

        x̄ = Set{Vector{Int}}([[0, 0, 0]])
        ȳ = 0

        # Model
        model = Model(() -> ToQUBO.Optimizer(ExactSampler.Optimizer))

        @variable(model, x[1:n], Bin)
        @objective(model, Max, x'A * x)
        @constraint(model, c1, x ∈ SOS1())

        optimize!(model)

        # Reformulation
        ρ = get_attribute(c1, Attributes.ConstraintEncodingPenalty())
        n, L, Q, α, β = QUBOTools.qubo(model, :dense)

        Q̂ = Q + diagm(L)

        @test ρ ≈ ρ̄
        @test α ≈ ᾱ
        @test β ≈ β̄
        @test Q̂ ≈ Q̄

        # Solutions
        x̂ = trunc.(Int, value.(x))
        ŷ = objective_value(model)

        @test x̂ ∈ x̄
        @test ŷ ≈ ȳ

        return nothing
    end
end
