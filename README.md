# IntegralArrays

Julia Implementation of Integral Arrays

[![Build status](https://github.com/JuliaImages/IntegralArrays.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaImages/IntegralArrays.jl/actions/workflows/CI.yml)

[![Coverage status](https://codecov.io/gh/JuliaImages/IntegralArrays.jl/branch/master/graph/badge.svg?token=oPz8fJvjDP)](https://codecov.io/gh/JuliaImages/IntegralArrays.jl)

IntegralArrays are useful for summing arrays over rectangular regions. Once created, the sum of an arbitrarily-large rectangular region
can be computed in `O(2^d)` adds, where `d` is the dimensionality.

Demo:

```
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

julia> sum(A[1:2, 1:2])
33

julia> Ai[1..2, 1..2]
33

julia> Ai[1..3, 2..4]
999

julia> sum(A[1:3, 2:4])
999
```
