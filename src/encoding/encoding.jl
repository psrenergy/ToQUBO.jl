module Encoding

import MathOptInterface as MOI
import PseudoBooleanOptimization as PBO

const VI = MOI.VariableIndex

include("interface.jl")
include("extras.jl")

include("variables/mirror.jl")
include("variables/interval/bounded.jl")
include("variables/interval/unary.jl")
include("variables/interval/binary.jl")
include("variables/interval/arithmetic.jl")

include("variables/set/one_hot.jl")
include("variables/set/domain_wall.jl")

# include("constraints/constraints.jl")

end