# IntegralArrays

Julia Implementation of Integral Arrays

[![Build status](https://github.com/JuliaImages/IntegralArrays.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaImages/IntegralArrays.jl/actions/workflows/CI.yml)

[![Coverage status](https://codecov.io/gh/JuliaImages/IntegralArrays.jl/branch/master/graph/badge.svg?token=oPz8fJvjDP)](https://codecov.io/gh/JuliaImages/IntegralArrays.jl)

IntegralArrays are useful for summing arrays over rectangular regions. Once created, the sum of an arbitrarily-large rectangular region
can be computed in `O(2^d)` adds, where `d` is the dimensionality.

Demo:

```julia
julia> using IntegralArrays, IntervalSets

julia> A = [1 2 3 4 5;
            10 20 30 40 50;
            100 200 300 400 500]
3×5 Matrix{Int64}:
   1    2    3    4    5
  10   20   30   40   50
 100  200  300  400  500

julia> Ai = IntegralArray(A)
3×5 IntegralArray{Int64, 2, Matrix{Int64}}:
   1    3    6    10    15
  11   33   66   110   165
 111  333  666  1110  1665

julia> sum(A[1:2, 1:2]) == Ai[2, 2]
true

julia> sum(A[1:3, 2:4]) == Ai[1..3, 2..4] 
true
```

When one needs to compute the sum/average of all blocks extracted from an image, pre-building
the integral array usually provides a more efficient computation.

```julia
using BenchmarkTools, IntegralArrays

# simplified 3x3 mean filter; only for demo purpose
function mean_filter_naive!(out, X)
    Δ = CartesianIndex(1, 1)
    for i in CartesianIndex(2, 2):CartesianIndex(size(X).-1)
        block = @view X[i-Δ: i+Δ]
        out[i] = mean(block)
    end
    return out
end
function mean_filter_integral!(out, X)
    iX = IntegralArray(X)
    for i in CartesianIndex(2, 2):CartesianIndex(size(X).-1)
        x, y = i.I
        out[i] = iX[x±1, y±1]/9
    end
    return out
end

X = Float32.(rand(1:5, 64, 64));
m1 = copy(X);
m2 = copy(X);

@btime mean_filter_naive!($m1, $X); # 65.078 μs (0 allocations: 0 bytes)
@btime mean_filter_integral!($m2, $X); # 12.161 μs (4 allocations: 16.17 KiB)
m1 == m2 # true
```
