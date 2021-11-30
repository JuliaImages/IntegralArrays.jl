using IntegralArrays, LinearAlgebra, IntervalSets
using ColorTypes, ColorVectorSpace
using ColorTypes.FixedPointNumbers
using OffsetArrays
using Test
using Documenter

@testset "meta-quality" begin
    if VERSION >= v"1.6"
        doctest(IntegralArrays; manual = false)
    end
end

@testset "IntegralArrays" begin
    a = zeros(10, 10)
    int_array = IntegralArray(a)
    @test all(int_array == a)

    a = ones(10,10)
    int_array = IntegralArray(a)
    chk = Array(1:10)
    @test all([vec(int_array[i, :]) == chk * i for i in 1:10])

    int_sum = int_array[1..5, 1..2]
    @test int_sum == 10.0
    int_sum = int_array[3 ± 2, 1..2]
    @test int_sum == 10.0
    int_sum = int_array[3 ± 2, 3 ± 2]
    @test int_sum == 25.0
    int_sum = int_array[1..2, 1..5]
    @test int_sum == 10.0
    int_sum = int_array[4..8, 4..8]
    @test int_sum == 25.0
    int_sum = int_array[6 ± 2, 6 ± 2]
    @test int_sum == 25.0
    int_sum = int_array[6 ± 2, 6 ± 2]
    @test int_sum == 25.0

    a = Array(reshape(1:100, 10, 10))
    int_array = IntegralArray(a)
    @test diag(int_array) == Array([1, 26,  108,  280,  575, 1026, 1666, 2528, 3645, 5050])

    int_sum = int_array[1..3, 1..3]
    @test int_sum == 108
    int_sum = int_array[2 ± 1, 2 ± 1]
    @test int_sum == 108
    int_sum = int_array[2 ± 1, 2 ± 1]
    @test int_sum == 108
    int_sum = int_array[1..5, 1..2]
    @test int_sum == 80
    int_sum = int_array[3 ± 2, 1..2]
    @test int_sum == 80
    int_sum = int_array[4..8, 4..8]
    @test int_sum == 1400
    int_sum = int_array[6 ± 2, 6 ± 2]
    @test int_sum == 1400
    int_sum = int_array[6 ± 2, 6 ± 2]
    @test int_sum == 1400

    I, Δ = CartesianIndex(6, 6), CartesianIndex(2, 2)
    @test int_array[I-Δ..I+Δ] == 1400

    @testset "OffsetArray" begin
        X = rand(1:5, 5, 5)
        iX = IntegralArray(X)
        @test axes(iX) == (1:5, 1:5)
        Xo = OffsetArray(X, -1, -1)
        iXo = IntegralArray(Xo)
        @test axes(iXo) == (0:4, 0:4)

        @test_throws DimensionMismatch IntegralArray(X, Xo)
    end

    @testset "in-place with buffer" begin
        X = collect(reshape(1:25, 5, 5))
        iX = similar(X)
        IntegralArray(iX, X)
        IntegralArray(X, X)
        @test iX == X == IntegralArray(reshape(1:25, 5, 5))
    end
end

@testset "Color integral arrays" begin
    A = [RGB{N0f8}(0.2, 0.8, 0), RGB{N0f8}(0.5, 0.3, 0)]
    intA = IntegralArray(A)
    a1, a2 = A
    @test intA[2] == RGB(Float32(red(a1))+Float32(red(a2)),
                         Float32(green(a1))+Float32(green(a2)),
                         Float32(blue(a1))+Float32(blue(a2)))
    @test intA[1..2] == intA[2]
    @test intA[2..2] ≈ A[2]
end
