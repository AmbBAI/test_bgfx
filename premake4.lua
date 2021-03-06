--
-- Copyright 2010-2015 Branimir Karadzic. All rights reserved.
-- License: http://www.opensource.org/licenses/BSD-2-Clause
--

newoption {
  trigger = "with-amalgamated",
  description = "Enable amalgamated build.",
}

newoption {
  trigger = "with-ovr",
  description = "Enable OculusVR integration.",
}

newoption {
  trigger = "with-sdl",
  description = "Enable SDL entry.",
}

newoption {
  trigger = "with-glfw",
  description = "Enable GLFW entry.",
}

newoption {
  trigger = "with-shared-lib",
  description = "Enable building shared library.",
}

newoption {
  trigger = "with-tools",
  description = "Enable building tools.",
}

solution "test_bgfx"
  configurations {
    "Debug",
    "Release",
  }

  if _ACTION == "xcode4" then
    platforms {
      "Universal",
    }
  else
    platforms {
      "x32",
      "x64",
--      "Xbox360",
      "Native", -- for targets where bitness is not specified
    }
  end

  language "C++"
  startproject "test_bgfx"

BGFX_DIR = path.getabsolute("./bgfx")
local BGFX_BUILD_DIR = "./build"
local BGFX_THIRD_PARTY_DIR = path.join(BGFX_DIR, "3rdparty")
BX_DIR = path.getabsolute(path.join(BGFX_DIR, "../bx"))

defines {
  "BX_CONFIG_ENABLE_MSVC_LEVEL4_WARNINGS=1"
}

buildoptions_cpp = buildoptions
dofile (path.join(BX_DIR, "scripts/toolchain.lua"))
if not toolchain(BGFX_BUILD_DIR, BGFX_THIRD_PARTY_DIR) then
  return -- no action specified
end

function copyLib()
end

if _OPTIONS["with-sdl"] then
  if os.is("windows") then
    if not os.getenv("SDL2_DIR") then
      print("Set SDL2_DIR enviroment variable.")
    end
  end
end

function createProject(_name)

  project (_name)
    uuid (os.uuid(_name))
    kind "WindowedApp"

  configuration {}

  debugdir "runtime/"

  includedirs {
    path.join(BX_DIR,   "include"),
    path.join(BGFX_DIR, "include"),
    path.join(BGFX_DIR, "3rdparty"),
    "common",
  }

  files {
    path.join(_name, "**.c"),
    path.join(_name, "**.cpp"),
    path.join(_name, "**.h"),
  }

  links {
    "bgfx",
    "common",
  }

  if _OPTIONS["with-sdl"] then
    defines { "ENTRY_CONFIG_USE_SDL=1" }
    links   { "SDL2" }

    configuration { "x32", "windows" }
      libdirs { "$(SDL2_DIR)/lib/x86" }

    configuration { "x64", "windows" }
      libdirs { "$(SDL2_DIR)/lib/x64" }

    configuration {}
  end

  if _OPTIONS["with-glfw"] then
    defines { "ENTRY_CONFIG_USE_GLFW=1" }
    links   {
      "glfw3"
    }

    configuration { "linux or freebsd" }
      links {
        "Xrandr",
        "Xinerama",
        "Xi",
        "Xxf86vm",
        "Xcursor",
      }

    configuration { "osx" }
      linkoptions {
        "-framework CoreVideo",
        "-framework IOKit",
      }

    configuration {}
  end

  if _OPTIONS["with-ovr"] then
    links   {
      "winmm",
      "ws2_32",
    }

    -- Check for LibOVR 5.0+
    if os.isdir(path.join(os.getenv("OVR_DIR"), "LibOVR/Lib/Windows/Win32/Debug/VS2012")) then

      configuration { "x32", "Debug" }
        libdirs { path.join("$(OVR_DIR)/LibOVR/Lib/Windows/Win32/Debug", _ACTION) }

      configuration { "x32", "Release" }
        libdirs { path.join("$(OVR_DIR)/LibOVR/Lib/Windows/Win32/Release", _ACTION) }

      configuration { "x64", "Debug" }
        libdirs { path.join("$(OVR_DIR)/LibOVR/Lib/Windows/x64/Debug", _ACTION) }

      configuration { "x64", "Release" }
        libdirs { path.join("$(OVR_DIR)/LibOVR/Lib/Windows/x64/Release", _ACTION) }

      configuration { "x32 or x64" }
        links { "libovr" }
    else
      configuration { "x32" }
        libdirs { path.join("$(OVR_DIR)/LibOVR/Lib/Win32", _ACTION) }

      configuration { "x64" }
        libdirs { path.join("$(OVR_DIR)/LibOVR/Lib/x64", _ACTION) }

      configuration { "x32", "Debug" }
        links { "libovrd" }

      configuration { "x32", "Release" }
        links { "libovr" }

      configuration { "x64", "Debug" }
        links { "libovr64d" }

      configuration { "x64", "Release" }
        links { "libovr64" }
    end

    configuration {}
  end

  configuration { "vs*" }
    linkoptions {
      "/ignore:4199", -- LNK4199: /DELAYLOAD:*.dll ignored; no imports found from *.dll
    }
    links { -- this is needed only for testing with GLES2/3 on Windows with VS2008
      "DelayImp",
    }

  configuration { "vs201*" }
    linkoptions { -- this is needed only for testing with GLES2/3 on Windows with VS201x
      "/DELAYLOAD:\"libEGL.dll\"",
      "/DELAYLOAD:\"libGLESv2.dll\"",
    }

  configuration { "mingw*" }
    targetextension ".exe"

  configuration { "vs20* or mingw*" }
    links {
      "gdi32",
      "psapi",
    }

  configuration { "winphone8* or winstore8*" }
    removelinks {
      "DelayImp",
      "gdi32",
      "psapi"
    }
    links {
      "d3d11",
      "dxgi"
    }
    linkoptions {
      "/ignore:4264" -- LNK4264: archiving object file compiled with /ZW into a static library; note that when authoring Windows Runtime types it is not recommended to link with a static library that contains Windows Runtime metadata
    }

  -- WinRT targets need their own output directories or build files stomp over each other
  configuration { "x32", "winphone8* or winstore8*" }
    targetdir (path.join(BGFX_BUILD_DIR, "win32_" .. _ACTION, "bin", _name))
    objdir (path.join(BGFX_BUILD_DIR, "win32_" .. _ACTION, "obj", _name))

  configuration { "x64", "winphone8* or winstore8*" }
    targetdir (path.join(BGFX_BUILD_DIR, "win64_" .. _ACTION, "bin", _name))
    objdir (path.join(BGFX_BUILD_DIR, "win64_" .. _ACTION, "obj", _name))

  configuration { "ARM", "winphone8* or winstore8*" }
    targetdir (path.join(BGFX_BUILD_DIR, "arm_" .. _ACTION, "bin", _name))
    objdir (path.join(BGFX_BUILD_DIR, "arm_" .. _ACTION, "obj", _name))

  configuration { "mingw-clang" }
    kind "ConsoleApp"

  configuration { "android*" }
    kind "ConsoleApp"
    targetextension ".so"
    linkoptions {
      "-shared",
    }
    links {
      "EGL",
      "GLESv2",
    }

  configuration { "nacl*" }
    kind "ConsoleApp"
    targetextension ".nexe"
    links {
      "ppapi",
      "ppapi_gles2",
      "pthread",
    }

  configuration { "pnacl" }
    kind "ConsoleApp"
    targetextension ".pexe"
    links {
      "ppapi",
      "ppapi_gles2",
      "pthread",
    }

  configuration { "asmjs" }
    kind "ConsoleApp"
    targetextension ".bc"

  configuration { "linux-* or freebsd" }
    links {
      "X11",
      "GL",
      "pthread",
    }

  configuration { "rpi" }
    links {
      "X11",
      "GLESv2",
      "EGL",
      "bcm_host",
      "vcos",
      "vchiq_arm",
      "pthread",
    }

  configuration { "osx" }
    files {
      "common/**.mm",
    }
    links {
      "Cocoa.framework",
      "OpenGL.framework",
    }

  configuration { "ios*" }
    kind "ConsoleApp"
    files {
      "common/**.mm",
    }
    linkoptions {
      "-framework CoreFoundation",
      "-framework Foundation",
      "-framework OpenGLES",
      "-framework UIKit",
      "-framework QuartzCore",
    }

  configuration { "xcode4", "ios" }
    kind "WindowedApp"
    files {
      path.join(BGFX_DIR, "examples/runtime/iOS-Info.plist"),
    }

  configuration { "qnx*" }
    targetextension ""
    links {
      "EGL",
      "GLESv2",
    }

  configuration {}

  strip()
end

dofile (path.join(BGFX_DIR, "scripts/bgfx.lua"))

-- group "libs"
bgfxProject("", "StaticLib", {})
dofile "common.lua"

createProject("test_bgfx")

if _OPTIONS["with-shared-lib"] then
  group "libs"
  bgfxProject("-shared-lib", "SharedLib", {})
end

if _OPTIONS["with-tools"] then
  group "tools"
  dofile (path.join(BGFX_DIR, "scripts/makedisttex.lua"))
  dofile (path.join(BGFX_DIR, "scripts/shaderc.lua"))
  dofile (path.join(BGFX_DIR, "scripts/texturec.lua"))
  dofile (path.join(BGFX_DIR, "scripts/geometryc.lua"))
end
