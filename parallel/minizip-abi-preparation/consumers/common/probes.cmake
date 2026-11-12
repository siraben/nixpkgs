option(MINIZIP_EXPECT_FILE_OFFSET_64 "Require the opt-in public ABI definition" ON)
foreach(language IN ITEMS c cpp)
    add_executable(directory_probe_${language} "${CMAKE_CURRENT_LIST_DIR}/directory_probe.${language}")
    target_link_libraries(directory_probe_${language} PRIVATE ${probe_minizip_target})
    target_compile_definitions(directory_probe_${language} PRIVATE
        EXPECT_FILE_OFFSET_64=$<BOOL:${MINIZIP_EXPECT_FILE_OFFSET_64}>)
endforeach()
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Export probe compilation commands" FORCE)
