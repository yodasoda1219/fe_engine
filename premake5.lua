newoption {
    trigger = "architecture",
    value = "ARCH",
    description = "The architecture to target",
    default = "x64"
}
architecture_ = _OPTIONS["architecture"]
include "premake/mono.lua"
include "premake/dotnet.lua"
default_mono_includedir = determine_mono_include(architecture_)
default_mono_libdir = determine_mono_libdir(architecture_)
function scandir(directory, pattern)
    if not directory then
        return {}
    end
    local i, t, popen = 0, {}, io.popen
    for filename in popen('find "' .. directory .. '" -maxdepth 1 -name "' .. pattern .. '"'):lines() do
        i = i + 1
        t[i] = filename
    end
    return t
end
function iterate_dlls()
    local directory = os.getenv("DOTNET_ASSEMBLY_PATH")
    local table = scandir(directory, "*.dll")
    for key, value in pairs(table) do
        links {
            (value)
        }
    end
end
newoption {
    trigger = "mono-include",
    value = "PATH",
    description = "The path to the Mono include directory",
    default = (default_mono_includedir)
}
newoption {
    trigger = "mono-libdir",
    value = "PATH",
    description = "The path to the Mono library directory",
    default = (default_mono_libdir)
}
newoption {
    trigger = "cs-version",
    value = "VER",
    description = "C# version to compile code as",
    default = "9.0"
}
newoption {
    trigger = "clear-mode",
    value = "MODE",
    description = "How to clear the screen each frame",
    default = "cursor-position",
    allowed = {
        { "cursor-position", "Reset the cursor position" },
        { "full-clear", "Clear every character on the screen (worse display)" }
    }
}
newoption {
    trigger = "dotnet-sdk-version",
    value = "VERSION",
    description = "The .NET Core SDK version to target; only applicable to Unix systems",
    default = "5.0.204"
}
includedirs_table = {}
libdirs_table = {}
includedirs_table["mono"] = _OPTIONS["mono-include"]
includedirs_table["cxxopts"] = "vendor/submodules/cxxopts/include"
libdirs_table["mono"] = _OPTIONS["mono-libdir"]
cs_version = _OPTIONS["cs-version"]
dotnet_framework_version = "4.5" -- sorry, option removed
dotnet_assembly_path = "%{libdirs_table.mono}/mono"
workspace "fe_engine"
    architecture (architecture_)
    targetdir "bin"
    configurations {
        "Debug",
        "Release"
    }
    flags {
        "MultiProcessorCompile"
    }
    startproject "host"
    filter "language:C#"
        disablewarnings {
            "CS8632",
            "CS0436",
            "CS0028",
        }
    filter "language:C++ or C"
        disablewarnings {
            "4244",
            "4267",
            "26451",
            "26812"
        }
    filter "system:windows"
        defines {
            "FEENGINE_WINDOWS"
        }
    filter "system:macosx"
        defines {
            "FEENGINE_MACOSX"
        }
    filter "system:linux"
        defines {
            "FEENGINE_LINUX"
        }
    filter "options:clear-mode=full-clear"
        defines {
            "CLEAR_MODE_FULL_CLEAR"
        }
    filter "configurations:Debug"
        defines {
            "FEENGINE_DEBUG"
        }
        symbols "on"
    filter "configurations:Release"
        defines {
            "FEENGINE_RELEASE"
        }
        optimize "on"
outputdir = "%{cfg.buildcfg}-%{cfg.system}-%{cfg.architecture}"
--include "premake/dependencies"
group "engine"
project "FEEngine"
    location "src/FEEngine"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")
    filter "system:windows"
        kind "SharedLib"
        language "C#"
        csversion (cs_version)
        framework (dotnet_framework_version)
        clr "unsafe"
        files {
            "src/%{prj.name}/**.cs",
            _SCRIPT
        }
        links {
            "System",
            "Newtonsoft.Json"
        }
    filter "action:gmake*"
        dotnet_project (generate_csharp_project("src/FEEngine", "FEEngine", "classlib", {}, {"vendor/submodules/Newtonsoft.Json/Src/Newtonsoft.Json/Newtonsoft.Json.csproj"}, ".", path.getdirectory(_SCRIPT)))
project "host"
    location "src/host"
    kind "ConsoleApp"
    language "C++"
    cppdialect "C++17"
    staticruntime "on"
    targetname "FEEngine"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")
    files {
        "src/%{prj.name}/**.cpp",
        "src/%{prj.name}/**.h"
    }
    includedirs {
        "%{includedirs_table.mono}",
        "%{includedirs_table.cxxopts}",
    }
    libdirs {
        "%{libdirs_table.mono}",
    }
    defines {
        'MONO_CS_LIBDIR="%{libdirs_table.mono}"'
    }
    debugargs {
        "-df",
        "ExampleGame.exe",
        "-e",
        "ExampleGame.Entrypoint"
    }
    filter "configurations:Debug"
        targetsuffix "-d"
        postbuildcommands {
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.dll" "."',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Core.dll" "."',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Data.dll" "."',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Numerics.dll" "."',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Runtime.Serialization.dll" "."',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Xml.dll" "."',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Xml.Linq.dll" "."',
        }
    filter "configurations:Release"
        debugdir "%{cfg.targetdir}"
        postbuildcommands {
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.dll" "%{cfg.targetdir}"',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Core.dll" "%{cfg.targetdir}"',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Data.dll" "%{cfg.targetdir}"',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Numerics.dll" "%{cfg.targetdir}"',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Runtime.Serialization.dll" "%{cfg.targetdir}"',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Xml.dll" "%{cfg.targetdir}"',
            '{COPY} "%{dotnet_assembly_path}/%{dotnet_framework_version}/System.Xml.Linq.dll" "%{cfg.targetdir}"',
        } 
    filter { "configurations:Debug", "system:windows" }
        postbuildcommands {
            '{MOVE} "%{cfg.targetdir}/FEEngine.dll" "."',
            '{MOVE} "%{cfg.targetdir}/ExampleGame.exe" "."',
            '{MOVE} "%{cfg.targetdir}/Newtonsoft.Json.dll" "."',
        }
    filter { "configurations:Debug", "system:not windows" }
        postbuildcommands {
            '{COPY} "%{cfg.targetdir}/../examples/ExampleGame/FEEngine.dll" "."',
            '{COPY} "%{cfg.targetdir}/../examples/ExampleGame/ExampleGame.dll" "."',
            '{COPY} "%{cfg.targetdir}/../examples/ExampleGame/Newtonsoft.Json.dll" "."',
        }
    filter "system:windows"
        links {
            "FEEngine",
            "ExampleGame",
            "Newtonsoft.Json",
            "mono-2.0-sgen.lib"
        }    
        defines {
            "_CRT_SECURE_NO_WARNINGS"
        }
        postbuildcommands {
            '{COPY} "%{libdirs_table.mono}/../bin/mono-2.0-sgen.dll" "%{cfg.targetdir}"',
        }
    filter "system:not windows"
        links {
            "monosgen-2.0"
        }
        dependson {
            "FEEngine",
            "ExampleGame",
            "Newtonsoft.Json"
        }
    filter "system:macosx"
        links {
            "z"
        }
        libdirs {
            "/usr/local/opt/zlib/lib"
        }
    filter "system:linux"
        links {
            "pthread",
            "stdc++fs"
        }
    filter "action:not gmake*"
        pchheader "pch.h"
        pchsource "src/%{prj.name}/pch.cpp"
group ""
group "tools"
project "SchemaGenerator"
    location "src/SchemaGenerator"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")
    filter "system:windows"
        kind "ConsoleApp"
        language "C#"
        csversion (cs_version)
        framework (dotnet_framework_version)
        files {
            "src/%{prj.name}/**.cs"
        }
        links {
            "FEEngine",
            "Newtonsoft.Json",
            "Newtonsoft.Json.Schema",
            "System"
        }
    filter "system:not windows"
        dotnet_project (generate_csharp_project("src/SchemaGenerator", "SchemaGenerator", "console", {}, {"src/FEEngine/FEEngine.csproj", "vendor/submodules/Newtonsoft.Json.Schema/Src/Newtonsoft.Json.Schema/Newtonsoft.Json.Schema.csproj"}, ".", path.getdirectory(_SCRIPT)))
project "MapDesigner"
    location "src/MapDesigner/Application"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")
    filter "system:windows"
        kind "ConsoleApp"
        language "C#"
        clr "unsafe"
        csversion (cs_version)
        framework (dotnet_framework_version)
        files {
            "src/MapDesigner/Application/**.cs"
        }
        excludes {
            "src/MapDesigner/Application/Platform/**.cs"
        }
        files {
            "src/MapDesigner/Application/Platform/%{cfg.platform}/**.cs"
        }
        links {
            "FEEngine",
            "Newtonsoft.Json",
            "MapDesigner-Internals",
            "System"
        }
    filter "system:not windows"
        dotnet_project (generate_csharp_project("src/MapDesigner/Application", "MapDesigner", "console", {}, {"src/FEEngine/FEEngine.csproj", "vendor/submodules/Newtonsoft.Json/Src/Newtonsoft.Json/Newtonsoft.Json.csproj"}, ".", path.getdirectory(_SCRIPT)))
        dependson {
            "MapDesigner-Internals"
        }
project "MapDesigner-Internals"
    location "src/MapDesigner/Internals"
    kind "SharedLib"
    language "C"
    staticruntime "on"
    targetdir ("bin/" .. outputdir .. "/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/%{prj.name}")
    files {
        "src/MapDesigner/Internals/**.c",
        "src/MapDesigner/Internals/**.h"
    }
    includedirs {
        "%{includedirs_table.mono}",
    }
    libdirs {
        "%{libdirs_table.mono}",
    }
    filter "system:windows"
        links {
            "mono-2.0-sgen.lib"
        }
        defines {
            "_CRT_SECURE_NO_WARNINGS"
        }
        postbuildcommands {
            '{COPY} "%{libdirs_table.mono}/../bin/mono-2.0-sgen.dll" "%{cfg.targetdir}"',
        }
    filter "system:not windows"
        links {
            "monosgen-2.0"
        }
    filter "system:macosx"
        links {
            "z"
        }
        libdirs {
            "/usr/local/opt/zlib/lib"
        }
    filter "system:linux"
        links {
            "pthread",
            "stdc++fs"
        }
    filter "action:not gmake*"
        pchheader "pch.h"
        pchsource "src/MapDesigner/Internals/pch.c"
group ""
group "examples"
project "ExampleGame"
    location "examples/ExampleGame"
    kind "ConsoleApp"
    language "C#"
    csversion (cs_version)
    framework (dotnet_framework_version)
    targetdir ("bin/" .. outputdir .. "/examples/%{prj.name}")
    objdir ("bin-int/" .. outputdir .. "/examples/%{prj.name}")
    files {
        "examples/%{prj.name}/**.cs"
    }
    links {
        "FEEngine"
    }
    filter "system:windows"
        links {
            "System"
        }
    filter "system:not windows"
        dotnet_project (generate_csharp_project("examples/ExampleGame", "ExampleGame", "console", {}, {"src/FEEngine/FEEngine.csproj"}, ".", path.getdirectory(_SCRIPT)))
group ""