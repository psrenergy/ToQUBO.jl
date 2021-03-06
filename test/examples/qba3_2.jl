@testset "Max-Cut" begin

#=
Quote from [1]:

The Max Cut problem is one of the most famous problems in combinatorial optimization.
Given an undirected graph G(V, E) with a vertex set V and an edge set E, the Max-Cut
problem seeks to partition V into two sets such that the number of edges between the
two sets (considered to be severed by the cut), is a large as possible.

Graph G:
(1)-(2)
 |   |
(3)-(4)
  \ /
  (5)
=#

⊻(x::VariableRef, y::VariableRef) = x + y - 2 * x * y

# :: Data ::
G = Dict{Tuple{Int, Int}, Float64}(
    (1, 2) => 1.0,
    (1, 3) => 1.0,
    (2, 4) => 1.0,
    (3, 4) => 1.0,
    (3, 5) => 1.0,
    (4, 5) => 1.0,
)
m = 5

# :: Results ::
Q̄ = [  2 -1 -1  0  0 
      -1  2  0 -1  0
      -1  0  3 -1 -1
       0 -1 -1  3 -1
       0  0 -1 -1  2 ]

c̄ = 0
x̄ = [0, 1, 1, 0, 0]
ȳ = 5

# :: Model ::
model = Model(() -> ToQUBO.Optimizer(ExactSampler.Optimizer))

@variable(model, x[i = 1:m], Bin)
@objective(model, Max, sum(Gᵢⱼ * (x[i] ⊻ x[j]) for ((i, j), Gᵢⱼ) in G))

optimize!(model)

vqm = unsafe_backend(model)

# Here we may need some introspection tools!
_, Q, c = ToQUBO.PBO.qubo_normal_form(vqm)

x̂ = value.(x)
ŷ = objective_value(model)

# :: Reformulation ::
@test c == c̄
@test Q == Q̄

# :: Solution ::
@test x̂ == x̄
@test ŷ == ȳ

end