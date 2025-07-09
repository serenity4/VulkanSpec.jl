using VulkanSpec
using VulkanSpec: VULKAN, VULKAN_SC
using StructArrays
using Test

@testset "VulkanSpec.jl" begin
  api = VulkanAPI(v"1.3.207")
  @test isa(api, VulkanAPI)
  @test api.version == v"1.3.207"
  @test length(api.structs) == 801
  @test length(api.unions) == 9
  @test length(api.functions) == 465
  @test length(api.symbols) == 4676
  @test length(api.aliases.dict) == 872
  @test length(api.symbols_including_aliases) == 5546 # disabled symbols are not included
  @test Set(api.symbols_including_aliases) == Set(api.symbols)
  @test issubset(keys(api.symbols), keys(api.symbols_including_aliases))
  @test allunique(keys(api.symbols_including_aliases))

  @testset "Extensions" begin
    extension = api.extensions["VK_KHR_swapchain"]
    @test extension.requirements == ["VK_KHR_surface"]
    @test extension.author == "KHR"
    @test extension.type == EXTENSION_TYPE_DEVICE
    symbols = defined_symbols(extension)
    @test length(symbols) == 38
    @test :vkCreateSwapchainKHR in symbols
    @test :VkSwapchainCreateInfoKHR in symbols

    name = "VK_IMG_filter_cubic"
    extension = api.extensions[name]
    @test extension.name == name
    @test extension.type === EXTENSION_TYPE_DEVICE
    @test extension.requirements == []
    @test extension.applicable == [VULKAN]
    @test extension.author == "IMG"
    @test length(extension.groups) === 1
    @test defined_symbols(extension) == [:VK_IMG_FILTER_CUBIC_SPEC_VERSION, :VK_IMG_FILTER_CUBIC_EXTENSION_NAME, :VK_FILTER_CUBIC_IMG, :VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_CUBIC_BIT_IMG]
    @test extension.platform == PLATFORM_NONE
    @test extension.is_provisional === false
    @test extension.promoted_to === nothing
    @test extension.deprecated_by === nothing
    @test extension.disabled === false

    name = "VK_KHR_mir_surface"
    extension = api.extensions[name]
    @test extension.name == name
    @test extension.type == EXTENSION_TYPE_INSTANCE
    @test extension.requirements == ["VK_KHR_surface"]
    @test extension.author == "KHR"
    @test length(extension.groups) == 1
    @test defined_symbols(extension) == [:VK_KHR_MIR_SURFACE_SPEC_VERSION, :VK_KHR_MIR_SURFACE_EXTENSION_NAME,]
    @test extension.disabled === true
    @test extension.platform == PLATFORM_NONE
    @test extension.is_provisional == false
    @test extension.promoted_to == nothing
    @test extension.deprecated_by == nothing

    name = "VK_EXT_debug_report"
    extension = api.extensions[name]
    @test extension.deprecated_by == "VK_EXT_debug_utils"

    name = "VK_KHR_sampler_mirror_clamp_to_edge"
    extension = api.extensions[name]
    @test extension.promoted_to == v"1.2.0"

    name = "VK_KHR_video_queue"
    extension = api.extensions[name]
    @test extension.is_provisional
    @test extension.requirements == ["VK_KHR_get_physical_device_properties2", "VK_KHR_sampler_ycbcr_conversion"]
  end

  @testset "Structs" begin
    name = :VkApplicationInfo
    @test api.structs[name] == SpecStruct(name, STYPE_GENERIC_INFO, false, [], StructVector([
      SpecStructMember(api.structs[name], :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(api.structs[name], :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :pApplicationName, :Cstring, true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :applicationVersion, :UInt32, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(api.structs[name], :pEngineName, :Cstring, true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :engineVersion, :UInt32, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(api.structs[name], :apiVersion, :UInt32, false, false, REQUIRED, nothing, [], true),
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
      SpecStructMember(api.structs[name], :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(api.structs[name], :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :flags, :VkInstanceCreateFlags, false, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :pApplicationInfo, :(Ptr{VkApplicationInfo}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :enabledLayerCount, :UInt32, false, false, OPTIONAL, nothing, [:ppEnabledLayerNames], true),
      SpecStructMember(api.structs[name], :ppEnabledLayerNames, :(Ptr{Cstring}), true, false, REQUIRED, :enabledLayerCount, [], true),
      SpecStructMember(api.structs[name], :enabledExtensionCount, :UInt32, false, false, OPTIONAL, nothing, [:ppEnabledExtensionNames], true),
      SpecStructMember(api.structs[name], :ppEnabledExtensionNames, :(Ptr{Cstring}), true, false, REQUIRED, :enabledExtensionCount, [], true),
    ]))

    name = :VkDescriptorSetLayoutBindingFlagsCreateInfo
    @test api.structs[name] == SpecStruct(name, STYPE_CREATE_INFO, false, [:VkDescriptorSetLayoutCreateInfo], StructVector([
      SpecStructMember(api.structs[name], :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(api.structs[name], :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :bindingCount, :UInt32, false, false, OPTIONAL, nothing, [:pBindingFlags], true),
      SpecStructMember(api.structs[name], :pBindingFlags, :(Ptr{VkDescriptorBindingFlags}), true, false, POINTER_REQUIRED, :bindingCount, [], true),
    ]))

    name = :VkDisplayPlaneInfo2KHR
    @test api.structs[name] == SpecStruct(name, STYPE_GENERIC_INFO, false, [], StructVector([
      SpecStructMember(api.structs[name], :sType, :VkStructureType, false, false, REQUIRED, nothing, [], true),
      SpecStructMember(api.structs[name], :pNext, :(Ptr{Cvoid}), true, false, OPTIONAL, nothing, [], true),
      SpecStructMember(api.structs[name], :mode, :VkDisplayModeKHR, false, true, REQUIRED, nothing, [], true),
      SpecStructMember(api.structs[name], :planeIndex, :UInt32, false, false, REQUIRED, nothing, [], true),
    ]))

    name = :VkTransformMatrixKHR
    @test api.structs[name] == SpecStruct(name, STYPE_DATA, false, [], StructVector([
      SpecStructMember(api.structs[name], :matrix, :(NTuple{3,NTuple{4,Float32}}), false, false, REQUIRED, nothing, [], true),
    ]))

    @testset "Members" begin
      strct = api.structs[:VkApplicationInfo]
      sType, pNext, pApplicationName, applicationVersion, pEngineName, engineVersion, apiVersion = strct
      @test sType.type == :VkStructureType && sType.requirement == REQUIRED
      @test pNext.type == :(Ptr{Cvoid}) && pNext.requirement == OPTIONAL && pNext.is_constant
      @test pApplicationName.type == :Cstring && pApplicationName.requirement == OPTIONAL && pApplicationName.is_constant
      @test applicationVersion.type == :UInt32 && applicationVersion.requirement == REQUIRED
      @test pEngineName.type == :Cstring && pEngineName.requirement == OPTIONAL && pEngineName.is_constant
      @test engineVersion.type == :UInt32 && engineVersion.requirement == REQUIRED
      @test apiVersion.type == :UInt32 && apiVersion.requirement == REQUIRED
      @test apiVersion.autovalidity
      @test !is_version(pEngineName, api.constants)
      @test is_version(apiVersion, api.constants)

      strct = api.structs[:VkAccelerationStructureBuildGeometryInfoKHR]
      sType, pNext, type, flags, mode, srcAccelerationStructure, dstAccelerationStructure, geometryCount, pGeometries, ppGeometries, scratchData = strct
      @test sType.type == :VkStructureType && sType.requirement == REQUIRED
      @test pNext.type == :(Ptr{Cvoid}) && pNext.requirement == OPTIONAL && pNext.is_constant
      @test type.type == :VkAccelerationStructureTypeKHR && type.requirement == REQUIRED
      @test flags.type == :VkBuildAccelerationStructureFlagsKHR && flags.requirement == OPTIONAL
      @test mode.type == :VkBuildAccelerationStructureModeKHR && mode.requirement == REQUIRED
      @test srcAccelerationStructure.type == :VkAccelerationStructureKHR && srcAccelerationStructure.requirement == OPTIONAL
      @test dstAccelerationStructure.type == :VkAccelerationStructureKHR && dstAccelerationStructure.requirement == OPTIONAL
      @test geometryCount.type == :UInt32 && geometryCount.requirement == OPTIONAL
      @test geometryCount.arglen == [:pGeometries, :ppGeometries]
      @test pGeometries.type == :(Ptr{VkAccelerationStructureGeometryKHR}) && pGeometries.requirement == OPTIONAL
      @test pGeometries.is_constant && pGeometries.len == :geometryCount
      @test ppGeometries.type == :(Ptr{Ptr{VkAccelerationStructureGeometryKHR}}) && ppGeometries.requirement == POINTER_OPTIONAL
      @test ppGeometries.is_constant && ppGeometries.len == :geometryCount
      @test scratchData.type == :VkDeviceOrHostAddressKHR && scratchData.requirement == REQUIRED
      @test !is_arr(pNext)
      @test !is_arr(geometryCount)
      @test is_arr(pGeometries)
      @test is_arr(ppGeometries)

      strct = api.structs[:VkDescriptorSetLayoutBinding]
      binding, descriptorType, descriptorCount, stageFlags, pImmutableSampler = strct
      # `descriptorCount` is not necessarily the length of another vector - it is the number of descriptors to be allocated, with no relation to the dimensions of other arguments. If provided, `pImmutableSampler` must have this length, but if not, the length can't be inferred.
      @test !is_inferable_length(descriptorCount)
      @test pImmutableSampler.requirement == OPTIONAL && pImmutableSampler.len == :descriptorCount
      @test len(pImmutableSampler) == descriptorCount
      @test arglen(descriptorCount) == [pImmutableSampler]
      @test !pImmutableSampler.autovalidity

      strct = api.structs[:VkShaderModuleCreateInfo]
      sType, pNext, flags, codeSize, pCode = strct
      @test flags.requirement == OPTIONAL
      @test pCode.len == :(codeSize / 4)
      @test codeSize.arglen == []
      @test ismissing(len(pCode))
      @test !is_length(codeSize) && !is_size(codeSize) # not directly, at least
      @test pImmutableSampler.requirement == OPTIONAL && pImmutableSampler.len == :descriptorCount
      @test len(pImmutableSampler) == descriptorCount
      @test arglen(descriptorCount) == [pImmutableSampler]
      @test !pImmutableSampler.autovalidity

      strct = api.structs[:VkWriteDescriptorSet]
      sType, pNext, dstSet, dstBinding, dstArrayElement, descriptorCount, descriptorType, pImageInfo, pBufferInfo, pTexelBufferView = strct
      @test len(pImageInfo) == len(pBufferInfo) == len(pTexelBufferView) == descriptorCount
      @test arglen(descriptorCount) == [pImageInfo, pBufferInfo, pTexelBufferView]
      # In the sense that it is the length of either of them (and others have zero count), not all of them.
      # See https://www.khronos.org/registry/vulkan/specs/1.1-extensions/html/vkspec.html#VkWriteDescriptorSet
      @test is_length_exception(descriptorCount)

      strct = api.structs[:VkSpecializationInfo]
      mapEntryCount, pMapEntries, dataSize, pData = strct
      @test mapEntryCount.arglen == [:pMapEntries] && arglen(mapEntryCount) == [pMapEntries]
      @test pMapEntries.len == :mapEntryCount && len(pMapEntries) == mapEntryCount
      @test dataSize.arglen == [:pData] && arglen(dataSize) == [pData]
      @test pData.len == :dataSize && len(pData) == dataSize
      @test is_length(mapEntryCount) && is_inferable_length(mapEntryCount)
      @test is_data(pData)
      @test is_size(dataSize) && !is_length(dataSize)

      strct = api.structs[:VkAccelerationStructureVersionInfoKHR]
      sType, pNext, pVersionData = strct
      @test !is_version(pVersionData, api.constants)
    end
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
        SpecFuncParam(api.functions[name], :pCreateInfo, :(Ptr{VkInstanceCreateInfo}), true, false, REQUIRED, nothing, [], true),
        SpecFuncParam(api.functions[name], :pAllocator, :(Ptr{VkAllocationCallbacks}), true, false, OPTIONAL, nothing, [], true),
        SpecFuncParam(api.functions[name], :pInstance, :(Ptr{VkInstance}), false, false, REQUIRED, nothing, [], true),
      ]), [:VK_SUCCESS], [:VK_ERROR_OUT_OF_HOST_MEMORY, :VK_ERROR_OUT_OF_DEVICE_MEMORY, :VK_ERROR_INITIALIZATION_FAILED, :VK_ERROR_LAYER_NOT_PRESENT, :VK_ERROR_EXTENSION_NOT_PRESENT, :VK_ERROR_INCOMPATIBLE_DRIVER])

    name = :vkCmdBindPipeline
    @test api.functions[name] == SpecFunc(name, FTYPE_COMMAND, :Cvoid, [RenderPassInside(), RenderPassOutside()], [QueueGraphics(), QueueCompute()], StructVector([
        SpecFuncParam(api.functions[name], :commandBuffer, :VkCommandBuffer, false, true, REQUIRED, nothing, [], true),
        SpecFuncParam(api.functions[name], :pipelineBindPoint, :VkPipelineBindPoint, false, false, REQUIRED, nothing, [], true),
        SpecFuncParam(api.functions[name], :pipeline, :VkPipeline, false, false, REQUIRED, nothing, [], true),
      ]), [], [])

    @testset "Classification" begin
      @test :vkCreateInstance in api.core_functions
      @test :vkEnumerateInstanceVersion in api.core_functions
      @test :vkGetInstanceProcAddr in api.instance_functions
      @test :vkEnumeratePhysicalDevices in api.instance_functions
      @test :vkCreateDevice in api.instance_functions
      @test :vkAllocateCommandBuffers in api.device_functions
      @test :vkGetDeviceProcAddr in api.device_functions
      nfunctionaliases = count(x -> haskey(api.functions, follow_alias(x, api.aliases)), keys(api.aliases.dict))
      n = length(api.functions) + nfunctionaliases
      @test n == sum(length, (api.core_functions, api.instance_functions, api.device_functions))
    end

    @testset "Parameters" begin
      func = api.functions[:vkCreateInstance]
      pCreateInfo, pAllocator, pInstance = func
      @test pCreateInfo.is_constant && pCreateInfo.requirement == REQUIRED
      @test pAllocator.is_constant && pAllocator.requirement == OPTIONAL
      @test !pInstance.is_constant && pInstance.requirement == REQUIRED
      @test pCreateInfo.type == :(Ptr{VkInstanceCreateInfo})
      @test pInstance.type == :(Ptr{VkInstance})
      @test pAllocator.type == :(Ptr{VkAllocationCallbacks})

      func = api.functions[:vkEnumeratePhysicalDevices]
      instance, pPhysicalDeviceCount, pPhysicalDevices = func
      @test instance.type == :VkInstance && instance.requirement == REQUIRED
      @test !pPhysicalDeviceCount.is_constant && pPhysicalDeviceCount.type == :(Ptr{UInt32})
      @test pPhysicalDeviceCount.requirement == POINTER_REQUIRED && pPhysicalDeviceCount.arglen == [:pPhysicalDevices]
      @test !pPhysicalDevices.is_constant && pPhysicalDevices.type == :(Ptr{VkPhysicalDevice})
      @test pPhysicalDevices.requirement == OPTIONAL && pPhysicalDevices.len == :pPhysicalDeviceCount

      func = api.functions[:vkCmdBindPipeline]
      commandBuffer, pipelineBindPoint, pipeline = func
      @test commandBuffer.type == :VkCommandBuffer && commandBuffer.requirement == REQUIRED
      @test commandBuffer.is_externsync
      @test pipelineBindPoint.type == :VkPipelineBindPoint && pipelineBindPoint.requirement == REQUIRED
      @test pipeline.type == :VkPipeline && pipeline.requirement == REQUIRED

      func = api.functions[:vkAllocateDescriptorSets]
      device, pAllocateInfo, pDescriptorSets = func
      @test device.type == :VkDevice && device.requirement == REQUIRED
      @test pAllocateInfo.type == :(Ptr{VkDescriptorSetAllocateInfo}) && pAllocateInfo.requirement == REQUIRED
      @test pAllocateInfo.is_constant && pAllocateInfo.is_externsync
      @test pDescriptorSets.type == :(Ptr{VkDescriptorSet}) && pDescriptorSets.requirement == REQUIRED
      @test pDescriptorSets.len == Symbol("pAllocateInfo->descriptorSetCount")

      func = api.functions[:vkFreeCommandBuffers]
      device, commandPool, commandBufferCount, pCommandBuffers = func
      @test device.type == :VkDevice && device.requirement == REQUIRED
      @test commandPool.type == :VkCommandPool && commandPool.requirement == REQUIRED
      @test commandPool.is_externsync
      @test commandBufferCount.type == :UInt32 && commandBufferCount.requirement == REQUIRED
      @test commandBufferCount.arglen == [:pCommandBuffers]
      @test pCommandBuffers.type == :(Ptr{VkCommandBuffer}) && pCommandBuffers.requirement == REQUIRED
      @test pCommandBuffers.is_constant && pCommandBuffers.len == :commandBufferCount
      @test pCommandBuffers.is_externsync
      @test len(pCommandBuffers) == commandBufferCount
      @test arglen(commandBufferCount) == [pCommandBuffers]
      @test !is_length_exception(commandBufferCount)
      @test is_inferable_length(commandBufferCount)
    end
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

    @test api.aliases[:VkImageMemoryBarrier2] == [:VkImageMemoryBarrier2KHR]
    @test api.aliases[:VkImageMemoryBarrier2KHR] == []
    @test api.aliases[:VkPhysicalDeviceVariablePointersFeatures] == [
      :VkPhysicalDeviceVariablePointerFeatures
      :VkPhysicalDeviceVariablePointerFeaturesKHR
      :VkPhysicalDeviceVariablePointersFeaturesKHR
    ]
  end

  @testset "Parameters" begin
    @test length_chain(api.functions[:vkAllocateDescriptorSets], "pAllocateInfo->descriptorSetCount", api.structs) == [
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

    handles_without_destructors = filter(x -> length(api.destructors[x]) == 0, api.handles.data)
    @test handles_without_destructors.name == [:VkPhysicalDevice, :VkQueue, :VkPerformanceConfigurationINTEL, :VkDisplayKHR, :VkDisplayModeKHR]

    handles_without_constructors = filter(x -> length(api.constructors[x]) == 0, api.handles.data)
    @test handles_without_constructors.name == setdiff(handles_without_destructors.name, [:VkDisplayModeKHR])

    handles_with_multiple_constructors = filter(x -> length(api.constructors[x]) > 1, api.handles.data)
    @test handles_with_multiple_constructors.name == [:VkPipeline, :VkRenderPass, :VkSurfaceKHR, :VkSwapchainKHR]
  end

  @testset "Constants" begin
    @test api.constants[:VK_UUID_SIZE] == SpecConstant(:VK_UUID_SIZE, 16)
    @test api.constants[:VK_MAX_MEMORY_HEAPS] == SpecConstant(:VK_MAX_MEMORY_HEAPS, 16)
    @test api.constants[:VkVideoDecodeFlagsKHR] == SpecConstant(:VkVideoDecodeFlagsKHR, :VkFlags)
    @test api.constants[:VK_KHR_DYNAMIC_RENDERING_EXTENSION_NAME] == SpecConstant(:VK_KHR_DYNAMIC_RENDERING_EXTENSION_NAME, "VK_KHR_dynamic_rendering")
  end

  @testset "Enums" begin
    @test api.enums[:VkIndexType] == SpecEnum(:VkIndexType, StructVector([
        SpecConstant(:VK_INDEX_TYPE_UINT16, 0),
        SpecConstant(:VK_INDEX_TYPE_UINT32, 1),
        SpecConstant(:VK_INDEX_TYPE_NONE_KHR, 1000165000),
        SpecConstant(:VK_INDEX_TYPE_UINT8_EXT, 1000265000),
    ]))
  end

  @testset "Bitmasks" begin
    @test api.bitmasks[:VkQueueFlagBits] == SpecBitmask(:VkQueueFlagBits, StructVector([
        SpecBit(:VK_QUEUE_GRAPHICS_BIT, 0),
        SpecBit(:VK_QUEUE_COMPUTE_BIT, 1),
        SpecBit(:VK_QUEUE_TRANSFER_BIT, 2),
        SpecBit(:VK_QUEUE_SPARSE_BINDING_BIT, 3),
        SpecBit(:VK_QUEUE_PROTECTED_BIT, 4),
        SpecBit(:VK_QUEUE_VIDEO_DECODE_BIT_KHR, 5),
        SpecBit(:VK_QUEUE_VIDEO_ENCODE_BIT_KHR, 6),
    ]), StructVector(SpecBitCombination[]), 32)

    @test api.bitmasks[:VkShaderStageFlagBits] == SpecBitmask(:VkShaderStageFlagBits, StructVector([
        SpecBit(:VK_SHADER_STAGE_VERTEX_BIT, 0),
        SpecBit(:VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT, 1),
        SpecBit(:VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT, 2),
        SpecBit(:VK_SHADER_STAGE_GEOMETRY_BIT, 3),
        SpecBit(:VK_SHADER_STAGE_FRAGMENT_BIT, 4),
        SpecBit(:VK_SHADER_STAGE_COMPUTE_BIT, 5),
        SpecBit(:VK_SHADER_STAGE_RAYGEN_BIT_KHR, 8),
        SpecBit(:VK_SHADER_STAGE_ANY_HIT_BIT_KHR, 9),
        SpecBit(:VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR, 10),
        SpecBit(:VK_SHADER_STAGE_MISS_BIT_KHR, 11),
        SpecBit(:VK_SHADER_STAGE_INTERSECTION_BIT_KHR, 12),
        SpecBit(:VK_SHADER_STAGE_CALLABLE_BIT_KHR, 13),
        SpecBit(:VK_SHADER_STAGE_TASK_BIT_NV, 6),
        SpecBit(:VK_SHADER_STAGE_MESH_BIT_NV, 7),
        SpecBit(:VK_SHADER_STAGE_SUBPASS_SHADING_BIT_HUAWEI, 14),
      ]), StructVector([
        SpecBitCombination(:VK_SHADER_STAGE_ALL_GRAPHICS, Int(0x0000001f)),
        SpecBitCombination(:VK_SHADER_STAGE_ALL, Int(0x7fffffff)),
      ]), 32)
  end

  @testset "Flags" begin
    @test api.flags[:VkFramebufferCreateFlags] == SpecFlag(:VkFramebufferCreateFlags, :VkFlags, api.bitmasks[:VkFramebufferCreateFlagBits])
    @test api.flags[:VkPipelineLayoutCreateFlags] == SpecFlag(:VkPipelineLayoutCreateFlags, :VkFlags, nothing)
  end

  @testset "Structure types" begin
    @test api.structure_types[:VkInstanceCreateInfo] == :VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
    @test api.structure_types[:VkGraphicsPipelineCreateInfo] == :VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO
    @test !haskey(api.structure_types, :VkBaseInStructure)
    @test !haskey(api.structure_types, :VkDevice)
  end

  @testset "Miscellaneous" begin
    @test api.authors["KHR"] == AuthorTag("KHR", "Khronos")
    @test api.authors["EXT"] == AuthorTag("EXT", "Multivendor")
    @test api.authors["NV"] == AuthorTag("NV", "NVIDIA Corporation")

    @test api.platforms[PLATFORM_WAYLAND] == SpecPlatform(PLATFORM_WAYLAND, "Wayland display server protocol")
    @test api.platforms[PLATFORM_WIN32] == SpecPlatform(PLATFORM_WIN32, "Microsoft Win32 API (also refers to Win64 apps)")
  end

  @testset "SPIR-V features" begin
    @testset "Capabilities" begin
      name = :Shader
      capability = api.capabilities_spirv[name]
      @test capability == SpecCapabilitySPIRV(name, v"1.0.0", [], [], [])

      name = :Geometry
      capability = api.capabilities_spirv[name]
      @test api.capabilities_spirv[name] == SpecCapabilitySPIRV(name, nothing, [], [FeatureCondition(:VkPhysicalDeviceFeatures, :geometryShader, nothing, nothing)], [])

      name = :StorageImageReadWithoutFormat
      capability = api.capabilities_spirv[name]
      @test api.capabilities_spirv[name] == SpecCapabilitySPIRV(name, v"1.3", ["VK_KHR_format_feature_flags2"], [FeatureCondition(:VkPhysicalDeviceFeatures, :shaderStorageImageReadWithoutFormat, nothing, nothing)], [])

      name = :GroupNonUniform
      capability = api.capabilities_spirv[name]
      @test api.capabilities_spirv[name] == SpecCapabilitySPIRV(name, nothing, [], [], [PropertyCondition(:VkPhysicalDeviceVulkan11Properties, :subgroupSupportedOperations, nothing, nothing, false, :VK_SUBGROUP_FEATURE_BASIC_BIT)])
    end

    @testset "Extensions" begin
      name = "SPV_KHR_variable_pointers"
      extension = api.extensions_spirv[name]
      @test extension == SpecExtensionSPIRV(name, v"1.1.0", ["VK_KHR_variable_pointers"])

      name = "SPV_NV_mesh_shader"
      extension = api.extensions_spirv[name]
      @test extension == SpecExtensionSPIRV("SPV_NV_mesh_shader", nothing, ["VK_NV_mesh_shader"])

      name = "SPV_KHR_multiview"
      extension = api.extensions_spirv[name]
      @test extension == SpecExtensionSPIRV("SPV_KHR_multiview", v"1.1.0", ["VK_KHR_multiview"])
    end

    @testset "Printing" begin
      for collection in (api.extensions, api.functions, api.structs, api.authors)
        @test isa(sprint(show, collection), String)
        @test isa(sprint(show, MIME"text/plain"(), collection), String)
      end
    end
  end

  @testset "New specification features & evolution" begin
    api_2 = VulkanAPI(v"1.3.240")
    @test isa(api_2, VulkanAPI)
    @test length(api_2.structs) > 100 + length(api.structs)
    @test all(length(getproperty(api_2, name)) > length(getproperty(api, name)) for name in (:structs, :functions, :aliases, :symbols))
    diff = Diff(api, api_2)
    @test all(!isbreaking, diff.removed)

    func = api_2.functions[:vkCmdSetSampleMaskEXT]
    commandBuffer, samples, pSampleMask = func
    @test pSampleMask.len == :((samples + 31) / 32)
    @test samples.arglen == []

    api_3 = VulkanAPI(v"1.3.266")
    diff = Diff(api_2, api_3)
    @test all(!isbreaking, diff.removed)

    api_4 = VulkanAPI(v"1.4.312")
    diff = Diff(api_3, api_4)
    @test all(!isbreaking, diff.removed)
    constructor = api_4.constructors[:vkCreatePipelineBinariesKHR]
    @test constructor.handle === api_4.handles[:VkPipelineBinaryKHR]
    @test constructor.batch === true
    @test constructor.create_info_struct === api_4.structs[:VkPipelineBinaryCreateInfoKHR]
  end
end;
