module IntegralArrays

# package code goes here
using Images, ClosedIntervals

import Base: size, getindex, linearindexing

export IntegralArray, ±, ..

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
sum = integral_array[CartesianIndex(y, x) ± σ]
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
immutable IntegralArray{T, N, A} <: AbstractArray{T, N}
	data::A
end

function IntegralArray(array::AbstractArray)
    integral_array = Array{Images.accum(eltype(array))}(size(array))
    sd = coords_spatial(array)
    cumsum!(integral_array, array, sd[1])
    for i = 2:length(sd)
        cumsum!(integral_array, integral_array, sd[i])
    end
    IntegralArray{eltype(array), ndims(array), typeof(array)}(integral_array)
end

..(x, y) = ClosedInterval(x, y)
±(x, y) = ClosedInterval(x + y, x - y)

function ±(x::CartesianIndex, y)
	ClosedInterval(x + y, x - y)
end

linearindexing(A::IntegralArray) = Base.LinearFast()
size(A::IntegralArray) = size(A.data)
getindex(A::IntegralArray, i::Int...) = A.data[i...]

function getindex(A::IntegralArray, i::ClosedInterval...)
	_boxdiff(A, left(i[1]), left(i[2]), right(i[1]), right(i[2]))
end

function _boxdiff{T}(int_array::IntegralArray{T, 2}, tl_y::Integer, tl_x::Integer, br_y::Integer, br_x::Integer)
    sum = int_array[br_y, br_x]
    sum -= tl_x > 1 ? int_array[br_y, tl_x - 1] : zero(T)
    sum -= tl_y > 1 ? int_array[tl_y - 1, br_x] : zero(T)
    sum += tl_y > 1 && tl_x > 1 ? int_array[tl_y - 1, tl_x - 1] : zero(T)
    sum
end

end # module
