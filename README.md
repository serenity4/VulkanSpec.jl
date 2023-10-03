# VulkanSpec

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://serenity4.github.io/VulkanSpec.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://serenity4.github.io/VulkanSpec.jl/dev/)
[![Build Status](https://github.com/serenity4/VulkanSpec.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/serenity4/VulkanSpec.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/serenity4/VulkanSpec.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/serenity4/VulkanSpec.jl)

[Vulkan](https://en.wikipedia.org/wiki/Vulkan) is a cross-platform graphics API for GPUs by Khronos. It is gigantic in size, and reflects the complexity found in modern day GPUs with varying designs and functionality. Fortunately, Khronos gives us tools to make sense of it, and to reduce the effort required in using it. The [specification document](https://registry.khronos.org/vulkan/specs/1.3-extensions/html/vkspec.html) is enormous however, and if you don't want to read it all, it's OK: you are just being a sane person. To the rescue, the [specification repository](https://github.com/KhronosGroup/Vulkan-Docs) hosts a [machine-readable version of the specification](https://github.com/KhronosGroup/Vulkan-Docs/blob/main/xml/vk.xml) under the form of an XML file.

If you were, say, trying to interface with the C Vulkan drivers (which are mere software libraries that conform to the API dictated by the Vulkan specification), you may find it (very) tedious to do everything by hand. Instead, you will want a wrapper for Vulkan written in your language of choice, e.g. Julia, such that you don't need to care about C interfacing details. For Julia, there is [Vulkan.jl](https://github.com/JuliaGPU/Vulkan.jl), and for other languages, you have [quite a few existing wrappers](https://vulkan.org/tools#language-bindings).

The functionality provided by this package was originally meant to help automate the generation of bindings for Julia, and was living under [Vulkan.jl](https://github.com/JuliaGPU/Vulkan.jl). However, it seemed like a good idea to split it out and enable new uses: with access to the structure of the Vulkan API, you can do more than generating wrappers. Here are a few ideas:
- Learning by inspecting the various parts of the API from the REPL.
- Making a Vulkan-aware IDE extension to bring practical information to the coding activity directly.
- Designing a web page targeted at exploration, learning and/or reference material.
- Creating easy-to-read diffs between Vulkan versions to facilitate keeping up with new functionality.

... and probably more!

Check out the **[DOCUMENTATION](https://serenity4.github.io/VulkanSpec.jl/dev/)** to get started.
