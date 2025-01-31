using OMAS
using Test

IMAS = OMAS.IMAS

@testset "base" begin
    ods = ODS()

    # TopIDS
    @test typeof(ods["equilibrium"]) <: ODS
    @test typeof(ods["equilibrium"].ids) <: IMAS.equilibrium

    # Traverse
    @test typeof(ods["equilibrium.time_slice"].ids) <: IMAS.IDSvector{<:IMAS.equilibrium__time_slice}

    # Dynamic path creation
    @test typeof(ods["equilibrium.time_slice.0"].ids) <: IMAS.equilibrium__time_slice
    @test length(ods["equilibrium.time_slice"]) == 1
    @test typeof(ods["equilibrium.time_slice"][1].ids) <: IMAS.equilibrium__time_slice
    @test length(ods["equilibrium.time_slice"]) == 2

    # Assignement
    @test (ods["dataset_description.data_entry.user"] = "bla") == "bla" == ods["dataset_description.data_entry.user"]

    # Keys
    @test keys(ods) == ["dataset_description", "equilibrium"]
    @test keys(ods["equilibrium.time_slice"]) == [1, 2]

    # Clearing
    ods["dataset_description.data_entry"] = ODS()
    @test ismissing(ods["dataset_description.data_entry"].ids, :user)

    # Data access as split dict
    ods["equilibrium"]["time_slice"][0]["time"] = 1000.0
    @test ods["equilibrium"]["time_slice"][0]["time"] == 1000.0
    ods["equilibrium"]["time_slice"][0]["global_quantities"]["ip"] = 1.5

    ods2 = deepcopy(ods)
    ods2["equilibrium"]["time_slice"][1] = ods["equilibrium"]["time_slice"][0]
    ods2["equilibrium.time_slice.1.time"] = 2000.0

    ods2["equilibrium"]["time_slice"][2] = deepcopy(ods["equilibrium"]["time_slice"][0])
    ods2["equilibrium.time_slice[2].time"] = 3000.0

    @test ods2["equilibrium"]["time_slice"][0]["time"] == 1000.0
    @test ods2["equilibrium"]["time_slice"][1]["time"] == 2000.0
    @test ods2["equilibrium"]["time_slice"][2]["time"] == 3000.0

    @test ods2["equilibrium"]["time_slice"][0]["global_quantities"].ulocation == ods2["equilibrium"]["time_slice"][2]["global_quantities"].ulocation
    @test ods2["equilibrium"]["time_slice"][0]["global_quantities"].ulocation == "equilibrium.time_slice.:.global_quantities"
    @test ods2["equilibrium"]["time_slice"][0]["global_quantities"].location == "equilibrium.time_slice.0.global_quantities"

    # check different ways of addressing data
    for item in (
        ods2["equilibrium.time_slice"]["1.global_quantities"],
        ods2[["equilibrium", "time_slice", 1, "global_quantities"]],
        ods2[("equilibrium", "time_slice", 1, "global_quantities")],
        ods2["equilibrium.time_slice.1.global_quantities"],
        ods2["equilibrium.time_slice[1].global_quantities"],
    )
        @test item.ulocation == "equilibrium.time_slice.:.global_quantities"
        @test item.location == "equilibrium.time_slice.1.global_quantities"
    end

    @test (ods2["equilibrium.time_slice.0.profiles_1d.psi"] = range(0, 1, 10)) == collect(range(0.0, 1.0, 10))

    @test "equilibrium" in ods2
    @test !("equilibrium" in ODS())

    ods = ODS()
    @test (ods.cocosio = 11) == 11
    @test_throws AssertionError ods.cocosio = 1
    ods.coordsio = Dict{String,Any}()
    @test (ods.coordsio = Dict{String,Any}()) == Dict{String,Any}()
    @test_throws AssertionError ods.coordsio = Dict{String,Any}("a" => 1)
    @test !(ods.unitsio = false)
    @test_throws AssertionError ods.unitsio = true
    @test !(ods.uncertainio = false)
    @test_throws AssertionError ods.uncertainio = true
end

@testset "PythonCall" begin
    np = OMAS.PythonCall.pyimport("numpy")

    ods = OMAS.ODS()
    ods["equilibrium.time"] = OMAS.PythonCall.PyList{Any}([1.0, 2.0, 3.0])
    ods["equilibrium.time"] = np.array([1, 2, 3]).astype(np.float32)
    ods["equilibrium.time"] = OMAS.PythonCall.PyArray(Float32[1.0, 2.0, 3.0, 4.0])
    ods["equilibrium.code.parameters"] = OMAS.PythonCall.PyDict()
end
