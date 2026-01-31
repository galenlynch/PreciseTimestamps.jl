using PreciseTimestamps
using Test: @testset, @test
using Dates: DateTime

@testset "PreciseTimestamps.jl" begin
    @testset "times" begin
        @test add_seconds(DateTime(2013, 7, 1), 1) ==
              PreciseDateTime(DateTime(2013, 7, 1, 0, 0, 1))

        @test duration(
            DateTime(2013, 7, 1, 0, 0, 0),
            0,
            DateTime(2013, 7, 1, 0, 0, 1),
            0,
        ) == 1

        @test datevec_to_precisedatetime(Float64[2017, 05, 14, 13, 53, 22.222]) ==
              PreciseDateTime(DateTime(2017, 05, 14, 13, 53, 22, 222))

    end
end
