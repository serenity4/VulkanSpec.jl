using VulkanSpec
using VulkanSpec: SpecHandle
using StructArrays
using Test

@testset "VulkanSpec.jl" begin
  api = VulkanAPI(v"1.3.207")
  @test isa(api, VulkanAPI)
  @test length(api.structs) == 750
  @test length(api.unions) == 9
  @test length(api.functions) == 465
  @test length(api.all_symbols) == 3412
  @test length(api.aliases.dict) == 872

  @testset "Structs" begin
    name = :VkApplicationInfo
    @test api.structs[name] == SpecStruct(name, STYPE_GENERIC_INFO, false, [], StructVector([
      SpecStructMember(name, :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :pApplicationName, :Cstring, true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :applicationVersion, :UInt32, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :pEngineName, :Cstring, true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :engineVersion, :UInt32, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :apiVersion, :UInt32, false, false, REQUIRED, nothing, [], true),
    ]))

    name = :VkPipelineViewportCoarseSampleOrderStateCreateInfoNV
    @test api.structs[name] == SpecStruct(name, STYPE_CREATE_INFO, false, [:VkPipelineViewportStateCreateInfo], StructVector([
      SpecStructMember(name, :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :sampleOrderType, :VkCoarseSampleOrderTypeNV, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :customSampleOrderCount, :UInt32, false, false, OPTIONAL, nothing, [:pCustomSampleOrders], true),
      SpecStructMember(name, :pCustomSampleOrders, :(Ptr{VkCoarseSampleOrderCustomNV}), true, false, REQUIRED, :customSampleOrderCount, [], true),
    ]))

    name = :VkInstanceCreateInfo
    @test api.structs[name] == SpecStruct(name, STYPE_CREATE_INFO, false, [], StructVector([
      SpecStructMember(name, :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :flags, :VkInstanceCreateFlags, false, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :pApplicationInfo, :(Ptr{VkApplicationInfo}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :enabledLayerCount, :UInt32, false, false, OPTIONAL, nothing, [:ppEnabledLayerNames], true),
      SpecStructMember(name, :ppEnabledLayerNames, :(Ptr{Cstring}), true, false, REQUIRED, :enabledLayerCount, [], true),
      SpecStructMember(name, :enabledExtensionCount, :UInt32, false, false, OPTIONAL, nothing, [:ppEnabledExtensionNames], true),
      SpecStructMember(name, :ppEnabledExtensionNames, :(Ptr{Cstring}), true, false, REQUIRED, :enabledExtensionCount, [], true),
    ]))

    name = :VkDescriptorSetLayoutBindingFlagsCreateInfo
    @test api.structs[name] == SpecStruct(name, STYPE_CREATE_INFO, false, [:VkDescriptorSetLayoutCreateInfo], StructVector([
      SpecStructMember(name, :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :bindingCount, :UInt32, false, false, OPTIONAL, nothing, [:pBindingFlags], true),
      SpecStructMember(name, :pBindingFlags, :(Ptr{VkDescriptorBindingFlags}), true, false, POINTER_REQUIRED, :bindingCount, [], true),
    ]))

    name = :VkDisplayPlaneInfo2KHR
    @test api.structs[name] == SpecStruct(name, STYPE_GENERIC_INFO, false, [], StructVector([
      SpecStructMember(name, :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(name, :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(name, :mode, :VkDisplayModeKHR, false, true, REQUIRED, nothing, [], true),
      SpecStructMember(name, :planeIndex, :UInt32, false, false, REQUIRED, nothing, [], true),
    ]))

    name = :VkTransformMatrixKHR
    @test api.structs[name] == SpecStruct(name, STYPE_DATA, false, [], StructVector([
      SpecStructMember(name, :matrix, :(NTuple{3,NTuple{4,Float32}}), false, false, REQUIRED, nothing, [], true),
    ]))
  end

  @testset "Unions" begin
    name = :VkClearColorValue
    @test api.unions[name] == SpecUnion(name, [:(NTuple{4,Float32}), :(NTuple{4,Int32}), :(NTuple{4,UInt32})], [:float32, :int32, :uint32], [], false)

    name = :VkPerformanceValueDataINTEL
    @test api.unions[name] == SpecUnion(name, [:UInt32, :UInt64, :Float32, :VkBool32, :Cstring], [:value32, :value64, :valueFloat, :valueBool, :valueString], [:VK_PERFORMANCE_VALUE_TYPE_UINT32_INTEL, :VK_PERFORMANCE_VALUE_TYPE_UINT64_INTEL, :VK_PERFORMANCE_VALUE_TYPE_FLOAT_INTEL, :VK_PERFORMANCE_VALUE_TYPE_BOOL_INTEL, :VK_PERFORMANCE_VALUE_TYPE_STRING_INTEL], false)
  end

  @testset "Functions" begin
    name = :vkCreateInstance
    @test api.functions[name] == SpecFunc(name, FTYPE_CREATE, :VkResult, [], [], StructVector([
        SpecFuncParam(name, :pCreateInfo, :(Ptr{VkInstanceCreateInfo}), true, false, REQUIRED, nothing, [], true),
        SpecFuncParam(name, :pAllocator, :(Ptr{VkAllocationCallbacks}), true, false, OPTIONAL, nothing, [], true),
        SpecFuncParam(name, :pInstance, :(Ptr{VkInstance}), false, false, REQUIRED, nothing, [], true),
      ]), [:VK_SUCCESS], [:VK_ERROR_OUT_OF_HOST_MEMORY, :VK_ERROR_OUT_OF_DEVICE_MEMORY, :VK_ERROR_INITIALIZATION_FAILED, :VK_ERROR_LAYER_NOT_PRESENT, :VK_ERROR_EXTENSION_NOT_PRESENT, :VK_ERROR_INCOMPATIBLE_DRIVER])

    name = :vkCmdBindPipeline
    @test api.functions[name] == SpecFunc(name, FTYPE_COMMAND, :Cvoid, [RenderPassInside(), RenderPassOutside()], [QueueGraphics(), QueueCompute()], StructVector([
        SpecFuncParam(name, :commandBuffer, :VkCommandBuffer, false, true, REQUIRED, nothing, [], true),
        SpecFuncParam(name, :pipelineBindPoint, :VkPipelineBindPoint, false, false, REQUIRED, nothing, [], true),
        SpecFuncParam(name, :pipeline, :VkPipeline, false, false, REQUIRED, nothing, [], true),
      ]), [], [])
  end

  @testset "Handles" begin
    @test api.handles[:VkInstance] == SpecHandle(:VkInstance, nothing, true)
    @test api.handles[:VkDevice] == SpecHandle(:VkDevice, :VkPhysicalDevice, true)
    @test api.handles[:VkDeviceMemory] == SpecHandle(:VkDeviceMemory, :VkDevice, false)
    @test api.handles[:VkDescriptorUpdateTemplate] == SpecHandle(:VkDescriptorUpdateTemplate, :VkDevice, false)
    @test !haskey(api.handles, :VkDescriptorUpdateTemplateKHR)
  end

  @testset "Aliases" begin
    @test isalias(:VkDescriptorUpdateTemplateKHR, api.aliases)
    @test hasalias(:VkDescriptorUpdateTemplate, api.aliases)
    @test isalias(:VkImageStencilUsageCreateInfoEXT, api.aliases)
    @test !isalias(:VkImageStencilUsageCreateInfo, api.aliases)

    @test follow_alias(:VkDescriptorUpdateTemplateKHR, api.aliases) == :VkDescriptorUpdateTemplate
    @test follow_alias(:VkPhysicalDeviceMemoryProperties2KHR, api.aliases) == :VkPhysicalDeviceMemoryProperties2
    @test follow_alias(:VkPhysicalDeviceMemoryProperties2, api.aliases) == :VkPhysicalDeviceMemoryProperties2
  end

  @testset "Parameters" begin
    @test length_chain(api.functions[:vkAllocateDescriptorSets][2], "pAllocateInfo->descriptorSetCount", api.structs) == [
      api.functions[:vkAllocateDescriptorSets][2],
      api.structs[:VkDescriptorSetAllocateInfo][4],
    ]
  end

  @testset "Constructors" begin
    name = :vkCreateInstance
    @test api.constructors[name] == CreateFunc(api.functions[name], api.handles[:VkInstance], api.structs[:VkInstanceCreateInfo], api.functions[name][1], false)

    name = :vkCreateGraphicsPipelines
    @test api.constructors[name] == CreateFunc(api.functions[name], api.handles[:VkPipeline], api.structs[:VkGraphicsPipelineCreateInfo], api.functions[name][4], true)

    name = :vkCreateRayTracingPipelinesKHR
    @test api.constructors[name] == CreateFunc(api.functions[name], api.handles[:VkPipeline], api.structs[:VkRayTracingPipelineCreateInfoKHR], api.functions[name][5], true)

    name = :vkAllocateDescriptorSets
    @test api.constructors[name] == CreateFunc(api.functions[name], api.handles[:VkDescriptorSet], api.structs[:VkDescriptorSetAllocateInfo], api.functions[name][2], true)

    name = :vkCreateFence
    @test api.constructors[name] == CreateFunc(api.functions[name], api.handles[:VkFence], api.structs[:VkFenceCreateInfo], api.functions[name][2], false)
  end

  @testset "Destructors" begin
    name = :vkDestroyInstance
    @test api.destructors[name] == DestroyFunc(api.functions[name], api.handles[:VkInstance], api.functions[name][1], false)

    name = :vkDestroyPipeline
    @test api.destructors[name] == DestroyFunc(api.functions[name], api.handles[:VkPipeline], api.functions[name][2], false)

    name = :vkFreeDescriptorSets
    @test api.destructors[name] == DestroyFunc(api.functions[name], api.handles[:VkDescriptorSet], api.functions[name][4], true)

    name = :vkDestroyFence
    @test api.destructors[name] == DestroyFunc(api.functions[name], api.handles[:VkFence], api.functions[name][2], false)
  end
end;
