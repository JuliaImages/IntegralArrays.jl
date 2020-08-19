module IntegralArrays

using FileIO # for loading images
using QuartzImageIO, ImageMagick, ImageSegmentation, ImageFeatures # for reading images
using Colors # for making images greyscale
using Images # for channelview; converting images to matrices
using ImageTransformations # for scaling high-quality images down

#=
Any one pixel in a given image has the value that is the sum of all of the pixels above it and to the left.
Original    Integral
+--------   +------------
| 1 2 3 .   | 1  3  6 .
| 4 5 6 .   | 5 12 21 .
| . . . .   | . . . . .
=#

function getImageMatrix(imageFile::AbstractString)
    img = load(imageFile)
    #img = imresize(img, ratio=1/8)

    # imgArr = convert(Array{Float64}, channelview(img)) # for coloured images
    imgArr = convert(Array{Float64}, Colors.Gray.(img))
    
    return imgArr
end

function toIntegralImage(imgArr::AbstractArray)
    
    arrRows, arrCols = size(imgArr) # get size only once in case
    rowSum = zeros(arrRows, arrCols)
    integralImageArr = zeros(arrRows, arrCols)
    
    # process the first column
    for x in 1:(arrRows)
        # we cannot access an element that does not exist if we are in the
        # top left corner of the image matrix
        if isone(x)
            integralImageArr[x, 1] = imgArr[x, 1]
        else
            integralImageArr[x, 1] = integralImageArr[x-1, 1] + imgArr[x, 1]
        end
    end
    
    # start processing columns
    for y in 1:(arrCols)
        # same as above: we cannot access a 0th element in the matrix
        # our scalar accumulator s will catch the 1st row, so we only
        # needed to predefine the first column before this loop
        if isone(y)
            continue
        end
        
        # get initial row
        s = imgArr[1, y] # scalar accumulator
        integralImageArr[1, y] = integralImageArr[1, y-1] + s
        
        # now start processing everything else
        for x in 1:(arrRows)
            if isone(x)
                continue
            end
            s = s + imgArr[x, y]
            integralImageArr[x, y] = integralImageArr[x, y-1] + s
        end
    end
    
    return integralImageArr
end

export getImageMatrix
export toIntegralImage

end # module
