set_languages("clatest", "cxxlatest")

add_rules "mode.debug"
add_rules "mode.release"

target "bin converter"
    set_kind "binary" 
    
    if is_mode("debug") then
        set_basename "bin_converter_debug"
        set_targetdir "bin"
    else 
        set_basename "bin_converter"
        set_targetdir "../"
    end

    set_objectdir "build/obj"
    
    add_includedirs "src/"
    add_files{ "src/**.cpp" }
    
target_end()
