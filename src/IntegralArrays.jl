module IntegralArrays

# package code goes here
using IntervalSets

export IntegralArray

"""
```
integral_array = IntegralArray(A)
```

Returns the integral array of an array. The integral array is calculated by assigning
to each cell the sum of all cells above it and to its left, i.e. the rectangle from
(1, 1) to the pixel. An integral array is a data structure which helps in efficient
calculation of sum of pixels in a rectangular subset of an array.

```
sum = integral_array[ytop..ybot, xtop..xbot]
sum = integral_array[y ± σy, x ± σx]
```

The sum of a window in an array can be directly calculated using four array references of
the integral array, irrespective of the size of the window, given the `yrange` and `xrange`
of the window. Given an integral array -

        A - - - - - - B -
        - * * * * * * * -
        - * * * * * * * -
        - * * * * * * * -
        - * * * * * * * -
        - * * * * * * * -
        C * * * * * * D -
        - - - - - - - - -

The sum of pixels in the area denoted by * is given by S = D + A - B - C.
"""
struct IntegralArray{T, N, A} <: AbstractArray{T, N}
    data::A
end

function IntegralArray(array::AbstractArray)
    integral_array = cumsum(array; dims=1)
    for i = 2:ndims(array)
        cumsum!(integral_array, integral_array; dims=i)
    end
    IntegralArray{eltype(array), ndims(array), typeof(integral_array)}(integral_array)
end

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

end # module
