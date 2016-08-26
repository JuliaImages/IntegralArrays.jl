module IntegralArraysTests

using IntegralArrays, Base.Test, FactCheck

facts("IntegralArrays") do
    a = zeros(10, 10)
    int_array = IntegralArray(a)
    @fact all(int_array == a) --> true

    a = ones(10,10)
    int_array = IntegralArray(a)
    chk = Array(1:10)
    @fact all([vec(int_array[i, :]) == chk * i for i in 1:10]) --> true

    int_sum = int_array[1..5, 1..2]
    @fact int_sum --> 10.0
    int_sum = int_array[3 ± 2, 1..2]
    @fact int_sum --> 10.0
    # int_sum = int_array[CartesianIndex((3, 3)) ± 2]
    # @fact int_sum --> 25.0
    int_sum = int_array[1..2, 1..5]
    @fact int_sum --> 10.0
    # int_sum = int_array[CartesianIndex((1, 1)), CartesianIndex((2, 5))]
    # @fact int_sum --> 10.0
    int_sum = int_array[4..8, 4..8]
    @fact int_sum --> 25.0
    int_sum = int_array[6 ± 2, 6 ± 2]
    @fact int_sum --> 25.0
    # int_sum = int_array[CartesianIndex((4, 4)), CartesianIndex((8, 8))]
    # @fact int_sum --> 25.0

    a = Array(reshape(1:100, 10, 10))
    int_array = IntegralArray(a)
    @fact int_array[diagind(int_array)] == Array([1, 26,  108,  280,  575, 1026, 1666, 2528, 3645, 5050]) --> true

    int_sum = int_array[1..3, 1..3]
    @fact int_sum --> 108
    int_sum = int_array[2 ± 1, 2 ± 1]
    @fact int_sum --> 108
    # int_sum = int_array[CartesianIndex((1, 1)), CartesianIndex((3, 3))]
    # @fact int_sum --> 108
    int_sum = int_array[1..5, 1..2]
    @fact int_sum --> 80
    int_sum = int_array[3 ± 2, 1..2]
    @fact int_sum --> 80
    # int_sum = int_array[CartesianIndex((1, 1)), CartesianIndex((5, 2))]
    # @fact int_sum --> 80
    int_sum = int_array[4..8, 4..8]
    @fact int_sum --> 1400
    int_sum = int_array[6 ± 2, 6 ± 2]
    @fact int_sum --> 1400
    # int_sum = int_array[CartesianIndex((4, 4)), CartesianIndex((8, 8))]
    # @fact int_sum --> 1400
end

end