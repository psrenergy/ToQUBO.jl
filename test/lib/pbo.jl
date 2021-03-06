@testset "PBO" verbose = true begin
# -*- Definitions -*-
S = Symbol
T = Float64

# :: Canonical Constructor ::
f = PBO.PBF{S, T}(Dict{Set{S}, T}(
    Set{S}() => 0.5,
    Set{S}([:x]) => 1.0,
    Set{S}([:y]) => 1.0,
    Set{S}([:z]) => 1.0,
    Set{S}([:x, :y]) => -2.0,
    Set{S}([:x, :z]) => -2.0,
    Set{S}([:y, :z]) => -2.0,
    Set{S}([:x, :y, :z]) => 3.0,
))
g = PBO.PBF{S, T}(Dict{Set{S}, T}(Set{S}() => 1.0))
h = PBO.PBF{S, T}(Dict{Set{S}, T}(
    Set{S}([:x]) => 1.0,
    Set{S}([:y]) => 1.0,
    Set{S}([:z]) => 1.0,
    Set{S}([:w]) => 1.0,
    Set{S}() => 1.0,
))
p = PBO.PBF{S, T}(Dict{Set{S}, T}(
    Set{S}() => 0.5,
    Set{S}([:x]) => 1.0,
    Set{S}([:x, :y]) => -2.0,
))
q = PBO.PBF{S, T}(Dict{Set{S}, T}(
    Set{S}() => 0.5,
    Set{S}([:y]) => 1.0,
    Set{S}([:x, :y]) => 2.0,
))
r = PBO.PBF{S, T}(
    Set{S}() => 1.0,
    Set{S}([:z]) => -1.0,
)
s = PBO.PBF{S, T}(
    Set{S}() => 0.0,
    Set{S}([:x, :y, :z]) => 3.0,
)

@testset "Constructors" begin
    @test PBO.PBF{S, T}(Set{S}() => 0.0) == PBO.PBF{S, T}() == zero(PBO.PBF{S, T})
    @test f == PBO.PBF{S, T}(
        nothing => 0.5,
        :x => 1.0,
        :y => 1.0,
        :z => 1.0,
        [:x, :y] => -2.0,
        [:x, :z] => -2.0,
        [:y, :z] => -2.0,
        [:x, :y, :z] => 3.0,
    )
    @test g == PBO.PBF{S, T}(1.0) == one(PBO.PBF{S, T})
    @test h == PBO.PBF{S, T}([:x, :y, :z, :w, nothing])
    @test p == PBO.PBF{S, T}((nothing, 0.5), :x, [:x, :y] => -2.0)
    @test q == PBO.PBF{S, T}(nothing => 0.5, :y, [:x, :y] =>  2.0)
    @test r == PBO.PBF{S, T}(nothing, :z => -1.0)
    @test s == PBO.PBF{S, T}(S[] => 0.0, Set{S}([:x, :y, :z]) => 3.0)
end

@testset "Arithmetic" verbose = true begin

@testset "+" begin
@test (p + q) == (q + p) == PBO.PBF{S, T}(
    nothing => 1.0, :x => 1.0, :y => 1.0
)

@test (p + q + r) == (r + q + p) == PBO.PBF{S, T}(
    nothing => 2.0, :x => 1.0, :y => 1.0, :z => -1.0
)

@test (s + 3.0) == (3.0 + s) == PBO.PBF{S, T}(
    nothing => 3.0, [:x, :y, :z] => 3.0
)
end

@testset "-" begin
@test (p - q) == PBO.PBF{S, T}(
    :x => 1.0, :y => -1.0, [:x, :y] => -4.0
)
@test (p - p) == (q - q) == (r - r) == (s - s) == PBO.PBF{S, T}()
@test (s - 3.0) == PBO.PBF{S, T}(
    nothing => -3.0, [:x, :y, :z] => 3.0,
)
@test (3.0 - s) == PBO.PBF{S, T}(
    nothing => 3.0, [:x, :y, :z] => -3.0,
)
end

@testset "*" begin
@test (p * q) == (q * p) == PBO.PBF{S, T}(
    nothing => 0.25, [:x] => 0.5, [:y] => 0.5, [:x, :y] => -3.0
)
@test (p * (-0.5)) == ((-0.5) * p) == PBO.PBF{S, T}(
    nothing => -0.25, :x => -0.5, [:x, :y] => 1.0
)
@test (0.25 * p + 0.75 * q) == PBO.PBF{S, T}(
    nothing => 0.5, :x => 0.25, :y => 0.75, [:x, :y] => 1.0
)
@test ((p * q * r) - s) == PBO.PBF{S, T}(
    nothing => 0.25,
    :x => 0.5,
    :y => 0.5,
    :z => -0.25,
    [:x, :y] => -3.0,
    [:x, :z] => -0.5,
    [:y, :z] => -0.5
)
end

@testset "/" begin
@test (p / 2.0) == (p * 0.5) == PBO.PBF{S, T}(nothing => 0.25, :x => 0.5, [:x, :y] => -1.0)
@test_throws DivideError p / 0.0
end

@testset "^" begin
@test (p ^ 0) == (q ^ 0) == (r ^ 0) == (s ^ 0) == one(PBO.PBF{S, T})

@test (p == (p ^ 1)) && (q == (q ^ 1)) && (r == (r ^ 1)) && (s == (s ^ 1))

@test (p ^ 2) == PBO.PBF{S, T}(nothing => 0.25, :x => 2.0, [:x, :y] => -2.0)
@test (q ^ 2) == PBO.PBF{S, T}(nothing => 0.25, :y => 2.0, [:x, :y] => 10.0)
@test (r ^ 2) == PBO.PBF{S, T}(nothing => 1.0, :z => -1.0)
@test (s ^ 2) == PBO.PBF{S, T}([:x, :y, :z] => 9.0)

@test (r ^ 3) == PBO.PBF{S, T}(nothing => 1.0, :z => -1.0)
@test (s ^ 3) == PBO.PBF{S, T}([:x, :y, :z] => 27.0)

@test (r ^ 4) == PBO.PBF{S, T}(nothing => 1.0, :z => -1.0)
end

end

@testset "QUBO" begin
x, Q, c = PBO.qubo_normal_form(Dict, p)
@test Q == Dict{Tuple{Int, Int}, T}(
    (x[:x], x[:x]) => 1.0, (x[:x], x[:y]) => -2.0
) && c == 0.5

x, Q, c = PBO.qubo_normal_form(Dict, q)
@test Q == Dict{Tuple{Int, Int}, T}(
    (x[:y], x[:y]) => 1.0, (x[:x], x[:y]) => 2.0
) && c == 0.5

x, Q, c = PBO.qubo_normal_form(Dict, r)
@test Q == Dict{Tuple{Int, Int}, T}(
    (x[:z], x[:z]) => -1.0
) && c == 1.0

x, Q, c = PBO.qubo_normal_form(Array, p)
@test Q == Symmetric(Array{T, 2}([1.0 -1.0; -1.0 0.0])) && c == 0.5

x, Q, c = PBO.qubo_normal_form(Array, q)
@test Q == Symmetric(Array{T, 2}([0.0 1.0; 1.0 1.0])) && c == 0.5

x, Q, c = PBO.qubo_normal_form(Array, r)
@test Q == Symmetric(Array{T, 2}([-1.0][:,:])) && c == 1.0

@test_throws Exception PBO.qubo_normal_form(Dict, s)
@test_throws Exception PBO.qubo_normal_form(Array, s)
end

@testset "Ising" begin end

@testset "Calculus" begin
@test PBO.gap(f; bound=:loose) == (PBO.upperbound(f; bound=:loose) - PBO.lowerbound(f; bound=:loose))
@test PBO.gap(g; bound=:loose) == (PBO.upperbound(g; bound=:loose) - PBO.lowerbound(g; bound=:loose))
@test PBO.gap(h; bound=:loose) == (PBO.upperbound(h; bound=:loose) - PBO.lowerbound(h; bound=:loose))
end

@testset "Quadratization" begin end

@testset "Discretization" begin
@test PBO.discretize(p; tol=0.1) == PBO.PBF{S, T}(
    nothing => 1.0, :x => 2.0, [:x, :y] => -4.0,
)
@test PBO.discretize(q; tol=0.1) == PBO.PBF{S, T}(
    nothing => 1.0, :y => 2.0, [:x, :y] =>  4.0,
)
@test PBO.discretize(r; tol=0.1) == PBO.PBF{S, T}(
    nothing => 1.0, :z => -1.0,
)
end

@testset "Print" begin
    @test "$(r)" == "1.0 - 1.0z" || "$(r)" == "-1.0z + 1.0"
    @test "$(s)" == "3.0x*y*z"
end

end