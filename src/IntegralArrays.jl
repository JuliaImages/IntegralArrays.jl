module IntegralArrays

using IntervalSets
using FixedPointNumbers: FixedPoint, floattype
using ColorTypes: Colorant

const .. = IntervalSets.:(..)
export IntegralArray, ..

"""
    iA = IntegralArray([buffer,] A)

Construct the integral array of the input array `A`. If buffer of the same shape as `A`
is provided, then this is a non-allocating version.

The integral array is calculated by assigning to each cell the sum of all cells above it and
to its left, i.e. the rectangle from origin point to the pixel position. For example, in 1-D
case, `iA[i] = sum(A[1:i])` if the vector `A`'s origin is 1.

```jldoctest; setup=:(using IntegralArrays)
julia> A = collect(reshape(1:25, 5, 5))
5×5 $(Matrix{Int}):
 1   6  11  16  21
 2   7  12  17  22
 3   8  13  18  23
 4   9  14  19  24
 5  10  15  20  25

julia> iA = IntegralArray(A)
5×5 IntegralArray{$Int, 2, $(Matrix{Int})}:
  1   7   18   34   55
  3  16   39   72  115
  6  27   63  114  180
 10  40   90  160  250
 15  55  120  210  325

julia> iA[3, 3] == sum(A[1:3, 1:3])
true

julia> iA[3..5, 3..5] == sum(A[3:5, 3:5])
true

julia> IntegralArray(A, A); # in-place modifying A itself

julia> A
5×5 $(Matrix{Int}):
  1   7   18   34   55
  3  16   39   72  115
  6  27   63  114  180
 10  40   90  160  250
 15  55  120  210  325
```

The closed interval `a..b` is used to support the integral array `iX` with a different
indexing semantic; `iX[a:b]` gives a subarray of `iX`, while `iX[a..b]` calculates the sum
of original array `X` over region `a:b`. `a ± σ` (can be typed by `\\pm<tab>`) is a
convenient constructor of the closed interval `a-σ..a+σ`.

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

@btime mean_filter_naive!(\$m1, \$X); # 65.078 μs (0 allocations: 0 bytes)
@btime mean_filter_integral!(\$m2, \$X); # 12.161 μs (4 allocations: 16.17 KiB)
m1 == m2 # true
```
"""
struct IntegralArray{T, N, A} <: AbstractArray{T, N}
    data::A
end

IntegralArray{T}(A::AbstractArray) where {T} = IntegralArray{T}(similar(A, T), A)
function IntegralArray{T}(data::AbstractArray, A::AbstractArray) where {T}
    axes(data) == axes(A) || throw(DimensionMismatch("integral data axes $(axes(data)) should be equal original array axes $(axes(A))."))
    cumsum!(data, A; dims=1)
    for i = 2:ndims(A)
        cumsum!(data, data; dims=i)
    end
    IntegralArray{T, ndims(data), typeof(data)}(data)
end

IntegralArray(A::AbstractArray) = IntegralArray{_maybe_floattype(eltype(A))}(A)
IntegralArray(data::AbstractArray, A::AbstractArray) =
    IntegralArray{_maybe_floattype(eltype(data))}(data, A)

# small integer eltypes almost certainly hit overflow issues (#15)
const SmallInt = @static if Int === Int64
    Union{Int8, UInt8, Int16, UInt16, Int32, UInt32}
else
    Union{Int8, UInt8, Int16, UInt16}
end
_widen(::Type{T}) where T<:SmallInt = T <: Signed ? Int : UInt
IntegralArray(A::AbstractArray{T}) where T<:SmallInt =
    IntegralArray{_maybe_floattype(_widen(T))}(A)
IntegralArray(data::AbstractArray{T}, A::AbstractArray) where T<:SmallInt =
    throw(ArgumentError("Small integer eltype $(T) would cause potential overflow issue, please use more bits for buffer array."))

Base.IndexStyle(::Type{IntegralArray{T,N,A}}) where {T,N,A} = IndexStyle(A)
Base.size(A::IntegralArray) = size(A.data)
Base.axes(A::IntegralArray) = axes(A.data)
Base.@propagate_inbounds Base.getindex(A::IntegralArray, i::Int) = A.data[i]
Base.@propagate_inbounds Base.getindex(A::IntegralArray{T,N}, i::Vararg{Int,N}) where {T,N} = A.data[i...]

Base.@propagate_inbounds function Base.getindex(A::IntegralArray{T,N}, i::Vararg{ClosedInterval{Int},N}) where {T,N}
    ret = zero(T)
    @boundscheck checkbounds(A, map(maximum, i)...)
    return _getindex(ret, A, axes(A), 1, (), i)
end

@inline _getindex(ret, A, ::Tuple{}, s, iint, ::Tuple{}) = (@inbounds(Ai = A[iint...]); ret + s * Ai)
@inline function _getindex(ret, A, axs, s, iint::Dims{M}, iiv::Tuple{ClosedInterval{Int},Vararg{ClosedInterval{Int}}}) where M
    ax1, axtail = axs[1], Base.tail(axs)
    iv1, ivtail = iiv[1], Base.tail(iiv)
    isempty(iv1) && return ret
    val  = _getindex(ret, A, axtail,  s, (iint..., maximum(iv1)), ivtail)
    imin = minimum(iv1) - 1
    checkindex(Bool, ax1, imin) || return val
    return _getindex(val, A, axtail, -s, (iint..., imin), ivtail)
end

Base.@propagate_inbounds function Base.getindex(A::IntegralArray{T,N}, r::ClosedInterval{CartesianIndex{N}}) where {T,N}
    A[map(.., r.left.I, r.right.I)...]
end


# only promote FixedPointNumber types(e.g., `N0f8`) to floats
# keeps consistant result for `Int` to Base
_maybe_floattype(::Type{CT}) where CT<:Colorant = floattype(CT)
_maybe_floattype(::Type{T}) where T<:FixedPoint = floattype(T)
_maybe_floattype(::Type{T}) where T = T

end # module
