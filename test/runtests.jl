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
    @test keys(ods) == [:dataset_description, :equilibrium]
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

end