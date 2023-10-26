function test_primes()
    @testset "Prime Factoring: 15 = 3 × 5" begin
        #  Problem Data  #
        R = 15
        a = ceil(Int, √R)
        b = ceil(Int, R ÷ 2)

        #  Solution Data  #
        ᾱ = 1
        β̄ = 49
        Q̄ = [
            -24  16  15  15  20  20  18   0  8  0
              0 -40  60  60 -20 -20   0  40 -8  8
              0   0 -40  98 -20   0 -18 -40 -8 -8
              0   0   0 -40   0 -20 -18 -40 -8 -8
              0   0   0   0  20   0   0   0  0  0
              0   0   0   0   0  20   0   0  0  0
              0   0   0   0   0   0  18   0  0  0
              0   0   0   0   0   0   0  40  0  0
              0   0   0   0   0   0   0   0 16  0
              0   0   0   0   0   0   0   0  0  8
        ]

        ρ̄ = 1
        p̄ = 3
        q̄ = 5

        model = Model(() -> ToQUBO.Optimizer(ExactSampler.Optimizer))

        @variable(model, 2 <= p <= a, Int)
        @variable(model, a <= q <= b, Int)
        @constraint(model, c1, p * q == R)

        set_optimizer_attribute(model, Attributes.StableQuadratization(), true)

        optimize!(model)

        @info MOI.get(unsafe_backend(model).target_model, MOI.ObjectiveSense())

        # Reformulation
        ρ = get_attribute(c1, Attributes.ConstraintEncodingPenalty())

        n, L, Q, α, β = QUBOTools.qubo(model, :dense)

        Q̂ = Q + diagm(L)

        @test n == 10
        @test ρ ≈ ρ̄
        @test α ≈ ᾱ
        @test β ≈ β̄
        @test Q̂ ≈ Q̄

        # Solutions
        p̂ = trunc(Int, value(p))
        q̂ = trunc(Int, value(q))

        @test p̂ == p̄
        @test q̂ == q̄

        return nothing
    end
end