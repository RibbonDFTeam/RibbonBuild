cmake_minimum_required(VERSION 3.10.0)

get_filename_component(PROJECT_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME_WE)

set(RibbonBuildPath "${CMAKE_CURRENT_SOURCE_DIR}/../../RibbonBuild")
set(RibbonComponentsPath
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
)

include(${RibbonBuildPath}/RibbonBuild.cmake)

project(${PROJECT_NAME} VERSION 0.0.1 LANGUAGES C CXX)
RibbonBuild()
