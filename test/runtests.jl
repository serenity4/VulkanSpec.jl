using VulkanSpec
using Test

@testset "VulkanSpec.jl" begin
  api = VulkanAPI(v"1.3.207")
  @test isa(api, VulkanAPI)
end;
