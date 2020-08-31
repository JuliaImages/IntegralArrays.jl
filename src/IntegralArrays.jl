#=
Rectangle features can be computed very rapidly using an intermediate representation for the image, which we call the integral image.
The integral image at location $x,y$ contains the sum of the pixels above and to the left of $x,y$ inclusive.
Original    Integral
+--------   +------------
| 1 2 3 .   | 1  3  6 .
| 4 5 6 .   | 5 12 21 .
| . . . .   | . . . . .
=#

module IntegralImage

import Base: size, getindex, LinearIndices
using Images: Images, coords_spatial


export to_int_img, sum_region


struct IntegralArray{T, N, A} <: AbstractArray{T, N}
	data::A
end


function to_int_img(img_arr::AbstractArray)
	#=
    Calculates the integral image based on this instance's original image data.
    
    parameter `imgArr`: Image source data [type: Abstract Array]
    
    return `integralImageArr`: Integral image for given image [type: Abstract Array]
    
    https://www.ipol.im/pub/art/2014/57/article_lr.pdf, p. 346
    
    This function is adapted from https://github.com/JuliaImages/IntegralArrays.jl/blob/a2aa5bb7c2d26512f562ab98f43497d695b84701/src/IntegralArrays.jl
    =#
	
	array_size = size(img_arr)
    int_img_arr = Array{Images.accum(eltype(img_arr))}(undef, array_size)
    sd = coords_spatial(img_arr)
    cumsum!(int_img_arr, img_arr; dims=sd[1])
    for i = 2:length(sd)
        cumsum!(int_img_arr, int_img_arr; dims=sd[i])
    end
	
    return Array{eltype(img_arr), ndims(img_arr)}(int_img_arr)
end

LinearIndices(A::IntegralArray) = Base.LinearFast()
size(A::IntegralArray) = size(A.data)
getindex(A::IntegralArray, i::Int...) = A.data[i...]
getindex(A::IntegralArray, ids::Tuple...) = getindex(A, ids[1]...)


function sum_region(ii_arr::AbstractArray, top_left::Tuple{Int64,Int64}, bot_right::Tuple{Int64,Int64})
    #=
    parameter `integralImageArr`: The intermediate Integral Image [type: Abstract Array]
    Calculates the sum in the rectangle specified by the given tuples:
        parameter `topLeft`: (x,y) of the rectangle's top left corner [type: Tuple]
        parameter `bottomRight`: (x,y) of the rectangle's bottom right corner [type: Tuple]
    
    return: The sum of all pixels in the given rectangle defined by the parameters topLeft and bottomRight
    =#
	
	sum = ii_arr[bot_right[2], bot_right[1]]
    sum -= top_left[1] > 1 ? ii_arr[bot_right[2], top_left[1] - 1] : 0
    sum -= top_left[2] > 1 ? ii_arr[top_left[2] - 1, bot_right[1]] : 0
    sum += top_left[2] > 1 && top_left[1] > 1 ? ii_arr[top_left[2] - 1, top_left[1] - 1] : 0
	
    return sum
end

end # end module
