using Documenter
using ToQUBO

# Set up to run docstrings with jldoctest
DocMeta.setdocmeta!(ToQUBO, :DocTestSetup, :(using ToQUBO); recursive = true)

makedocs(;
    modules  = [ToQUBO],
    doctest  = true,
    clean    = true,
    warnonly = [:missing_docs, :cross_references],
    format   = Documenter.HTML( #
        sidebar_sitename = false,
        mathengine       = Documenter.KaTeX(
            Dict(
                :macros => Dict(raw"\set" => raw"\left\lbrace{#1}\right\rbrace")
            )
        ),
        assets = [ #
            "assets/extra_styles.css",
            "assets/favicon.ico",
            # asset("https://tikzjax.com/v1/fonts.css"; class = :css),
            # asset("https://tikzjax.com/v1/tikzjax.js"; class = :js),
        ]
    ),
    sitename = "ToQUBO.jl",
    authors  = "Pedro Maciel Xavier and Pedro Ripper and Tiago Andrade and Joaquim Dias Garcia and David E. Bernal Neira",
    pages    = [ # 
        "Home"   => "index.md",
        "Manual" => [ #
            "Getting Started"   => "manual/1-start.md",
            "Running a Model"   => "manual/2-model.md",
            "Gathering Results" => "manual/3-results.md",
            "Compiler Settings" => "manual/4-settings.md"
        ],
        "Examples" => [ #
            "Knapsack"               => "examples/knapsack.md",
            "Integer Factorization"  => "examples/integer_factorization.md",
            "Portfolio Optimization" => "examples/portfolio_optimization.md",
        ],
        "Booklet" => [ #
            "Introduction"    => "booklet/1-intro.md",
            "QUBO"            => "booklet/2-qubo.md",
            "PBO"             => "booklet/3-pbo.md",
            "Encoding"        => "booklet/4-encoding.md",
            "Virtual Mapping" => "booklet/5-virtual.md",
            "The Compiler"    => "booklet/6-compiler.md",
            "Solvers"         => "booklet/7-solvers.md",
            "Appendix"        => "booklet/8-appendix.md",
        ]
    ],
    workdir = @__DIR__,
)

if "--skip-deploy" ∈ ARGS
    @warn "Skipping deployment"
else
    deploydocs(repo = raw"github.com/psrenergy/ToQUBO.jl.git", push_preview = true)
end
