require("premake_modules/export-compile-commands")
require("premake_modules/cmake")

workspace "workspace"
    configurations { "Debug", "Release" }
    platforms { "x32", "x64" }

    location "premake"
    
    filter {"system:windows"}
        characterset "MBCS"
    filter {}

    -- Set up platforms 
    filter {"platforms:x32"}
        architecture "x32"
    filter {"platforms:x64"}
        architecture "x64"
    filter {}

    cppdialect "C++17"

    -- Setup c++ spec per platform
    -- Linux uses a buildoption to allow for more
    -- up to date standards (2a)
    filter {"system:windows"}
        toolset "msc-v141"
    filter {"system:linux"}
        toolset "clang" -- prefer clang over gcc
        -- buildoptions "-std=c++17"
    filter {}

    -- Setup configurations
    filter "configurations:Debug"
        defines { "DEBUG", "_DEBUG" }
        optimize "Off"
        runtime "Debug"
        
        filter {"system:windows"}
            symbols "Full" -- We need symbols Full instead of just On
        filter {"system:linux"}
            symbols "On"
            buildoptions "-g3" -- need this for gdb
        filter {}

    filter {"configurations:Release"}
        defines { "NDEBUG" }
        optimize "Full"
        symbols "Off"
        flags {"LinkTimeOptimization"}
        
    filter {}
    
    project "project"
        kind "ConsoleApp"
        language "C++"
        targetdir "bin/%{cfg.buildcfg}"
        
        -- Windows and linux use different precompiled header path locations
        filter {"system:linux"}
            pchheader "src/precompiled.hh"
        filter {"system:windows"}
            pchheader "precompiled.hh"
        filter {}
        
        pchsource "src/precompiled.cc"
        
        includedirs { "src" }
        files { "src/**.hh", "src/**.cc" }

        -- For moving the compile commands into the root directory of the project
        -- so that autocomplete tools can see them (cquery...)
        
        -- This is messy but was the only way to get it to work consistently
        -- across multiple platforms (circleci, windows 10, vsts...)
        filter "system:linux"
            postbuildcommands {
                "{MKDIR} %{wks.location}/compile_commands/",
                "{TOUCH} %{wks.location}/compile_commands/%{cfg.shortname}.json",
                "{COPY} %{wks.location}/compile_commands/%{cfg.shortname}.json ../compile_commands.json"
            }
        filter "system:windows"
            postbuildcommands {
                "cmd.exe /c \"" .. "{MKDIR} %{wks.location}/compile_commands/",
                "cmd.exe /c \""  .. "{TOUCH} %{wks.location}/compile_commands/%{cfg.shortname}.json",
                "cmd.exe /c \""  .. "{COPY} %{wks.location}/compile_commands/%{cfg.shortname}.json ../compile_commands.json*"
            }
