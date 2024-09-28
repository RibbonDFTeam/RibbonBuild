set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

macro(TargetInit)
    set(SRC_DIRS "")
    set(PUBLIC_HEADERS "")
    set(INTERFACE_HEADERS "")
    set(PRIVATE_HEADERS "")

    set(DEPEND_COMPONENTS "")
    set(DEPEND_LIBS "")
    set(CUSTOM_CMAKE_C_FLAGS "")
    set(CUSTOM_CMAKE_CXX_FLAGS "")
    set(CUSTOM_CMAKE_EXE_LINKER_FLAGS "")
    set(CUSTOM_DEFINES "")
endmacro()

macro(TargetConfig)
    string(REPLACE " " ";" TARGET_CMAKE_C_FLAGS "${CMAKE_C_FLAGS};${CUSTOM_CMAKE_C_FLAGS}")
    string(REPLACE " " ";" TARGET_CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS};${CUSTOM_CMAKE_CXX_FLAGS}")
    string(REPLACE " " ";" TARGET_CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS};${CUSTOM_CMAKE_EXE_LINKER_FLAGS}")
    string(REPLACE " " ";" TARGET_DEFINES "${CUSTOM_DEFINES}")

    message(STATUS "TARGET_CMAKE_EXE_LINKER_FLAGS: ${TARGET_CMAKE_EXE_LINKER_FLAGS}")
    message(STATUS "TARGET_CMAKE_C_FLAGS: ${TARGET_CMAKE_C_FLAGS}")
    message(STATUS "TARGET_CMAKE_CXX_FLAGS: ${TARGET_CMAKE_CXX_FLAGS}")
    message(STATUS "TARGET_DEFINES: ${TARGET_DEFINES}")

    foreach(PUBLIC_HEADER ${PUBLIC_HEADERS})
        target_include_directories(${target_name} PUBLIC ${PUBLIC_HEADER})
    endforeach(PUBLIC_HEADER ${PUBLIC_HEADERS})

    message(STATUS "Public Headers: ${PUBLIC_HEADERS}")

    foreach(INTERFACE_HEADER ${INTERFACE_HEADERS})
        target_include_directories(${target_name} INTERFACE ${INTERFACE_HEADER})
    endforeach(INTERFACE_HEADER ${INTERFACE_HEADERS})

    message(STATUS "Interface Headers: ${INTERFACE_HEADERS}")

    foreach(PRIVATE_HEADER ${PRIVATE_HEADERS})
        target_include_directories(${target_name} PRIVATE ${PRIVATE_HEADER})
    endforeach(PRIVATE_HEADER ${PRIVATE_HEADERS})

    message(STATUS "Private Headers: ${PRIVATE_HEADERS}")

    message(STATUS "Sources: ${SRC}")

    foreach(depend_component ${DEPEND_COMPONENTS})
        add_dependencies(${target_name} ${depend_component})
        target_link_libraries(${target_name} PRIVATE ${depend_component})
    endforeach()

    message(STATUS "Depend components: ${DEPEND_COMPONENTS}")

    foreach(depend_lib ${DEPEND_LIBS})
        target_link_libraries(${target_name} PRIVATE ${depend_lib})
    endforeach()

    message(STATUS "Depend librarys: ${DEPEND_LIBS}")

    target_compile_options(${target_name} PRIVATE "${TARGET_CMAKE_C_FLAGS}")
    target_compile_options(${target_name} PRIVATE "${TARGET_CMAKE_CXX_FLAGS}")
    target_link_options(${target_name} PRIVATE "${TARGET_CMAKE_EXE_LINKER_FLAGS}")
    target_compile_definitions(${target_name} PRIVATE ${TARGET_DEFINES})

    if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
        set_target_properties(${target_name} PROPERTIES
            OUTPUT_NAME ${target_name}
            DEBUG_POSTFIX "_debug"
        )
    endif()

    install(TARGETS ${target_name}
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)

    install(DIRECTORY ${PUBLIC_HEADERS} DESTINATION include/${target_name})
    install(DIRECTORY ${INTERFACE_HEADERS} DESTINATION include/${target_name})
endmacro()

function(RibbonBuildApplication)
    get_filename_component(target_name ${CMAKE_CURRENT_SOURCE_DIR} NAME_WE)

    message("Register Application: [${target_name}]")

    set(SRC "")

    foreach(SRC_DIR ${SRC_DIRS})
        aux_source_directory(${SRC_DIR} SRC)
    endforeach(SRC_DIR ${SRC_DIRS})

    add_executable(${target_name} ${SRC})

    set_target_properties(${target_name} PROPERTIES INSTALL_RPATH "../lib")
    set_target_properties(${target_name} PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)

    TargetConfig()
endfunction()

function(RibbonBuildComponent)
    get_filename_component(target_name ${CMAKE_CURRENT_SOURCE_DIR} NAME_WE)

    message("Register Component: [${target_name}]")

    set(component_dynamic "STATIC")

    if(ARGN)
        list(GET ARGN 0 component_dynamic)
    endif()

    if(${component_dynamic} STREQUAL "DYNAMIC")
        set(LIBRARY_TYPE SHARED)
    else()
        set(LIBRARY_TYPE STATIC)
    endif()

    message(STATUS "LIBRARY_TYPE: ${LIBRARY_TYPE}")

    foreach(SRC_DIR ${SRC_DIRS})
        aux_source_directory(${SRC_DIR} SRC)
    endforeach(SRC_DIR ${SRC_DIRS})

    add_library(${target_name} ${LIBRARY_TYPE} ${SRC})

    TargetConfig()
endfunction()

function(ComponentEnable component_name value)
    string(TOUPPER "CONFIG_MODULE_${component_name}_ENABLE" component_config)
    set(${value} "${${component_config}}" PARENT_SCOPE)

    # message(STATUS "${component_config}=${${component_config}}")
endfunction()

function(BuildTargets targets_path_list)
    message("Build Targets start")

    foreach(target_path ${targets_path_list})
        get_filename_component(target_name ${target_path} NAME_WE)
        ComponentEnable(${target_name} target_enable)

        if(${target_enable})
            message(STATUS "Target [${target_name}] enable")
            TargetInit()
            add_subdirectory(${target_path} "${PROJECT_SOURCE_DIR}/build/${target_name}")
        else()
            message(STATUS "Target [${target_name}] disabled")
        endif()
    endforeach()
endfunction()

# @brief 在指定路径下查找库
# @param target_path 查找库的路径
# @return
function(ScanTarget target_path)
    message("Scan Targets in PATH: ${target_path}")

    # 遍历指定文件夹下的第一层文件夹下是否有CMakeLists.txt文件
    file(GLOB scan_paths "${target_path}/*")

    # message(STATUS "targets_list: ${targets_list}")
    set(targets_list "")

    foreach(scan_path ${scan_paths})
        if(IS_DIRECTORY ${scan_path})
            if(EXISTS "${scan_path}/CMakeLists.txt")
                # get_filename_component(target_name ${scan_path} NAME)
                list(APPEND targets_list ${scan_path})
                message(STATUS "find target: ${scan_path}")
            endif()
        endif()
    endforeach()

    # targets中添加扫描到的
    set(tmp_targets ${targets})
    list(APPEND tmp_targets ${targets_list})
    set(targets ${tmp_targets} PARENT_SCOPE)
endfunction()

function(RibbonBuild)
    # 扫描目标
    set(targets "")

    foreach(target_path ${RibbonComponentsPath})
        ScanTarget(${target_path})
    endforeach(target_path ${RibbonComponentsPath})

    if(NOT targets)
        message(FATAL_ERROR "Not find any module, exit build.")
    endif()

    # 注册目标
    BuildTargets("${targets}")
endfunction()

function(KconfigSetup)
    message("Kconfig Setup")

    add_custom_target(menuconfig
        COMMAND python "${RibbonBuildPath}/RibbonKconfig.py" "-m${PROJECT_SOURCE_DIR}"
        COMMAND cd "${PROJECT_SOURCE_DIR}/build"
        COMMAND rm -rf CMakeFiles
        COMMAND rm -rf CMakeCache.txt
        COMMAND cmake ".."
        COMMENT "execute menuconfig"
    )

    add_custom_target(distclean
        COMMAND python "${RibbonBuildPath}/RibbonKconfig.py" "-d${PROJECT_SOURCE_DIR}&"
        COMMENT "clean kconfig files"
        COMMAND exit
    )

    if(EXISTS "${PROJECT_SOURCE_DIR}/build/Kconfig")
        return()
    endif()

    message(STATUS "Kconfig init")

    # message(STATUS "${RibbonBuildPath}/RibbonKconfig.py -i${PROJECT_SOURCE_DIR};${RibbonComponentsPath}")
    execute_process(
        COMMAND python "${RibbonBuildPath}/RibbonKconfig.py" "-i${PROJECT_SOURCE_DIR};${RibbonComponentsPath}"
        RESULT_VARIABLE return_code
        OUTPUT_VARIABLE python_output
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(return_code EQUAL 0)
        message(STATUS "Kconfig files generated")
    else()
        message(FATAL_ERROR "Kconfig files generate failed, return_code:${return_code}")
    endif()
endfunction()

macro(ConfigProject)
    include(${PROJECT_SOURCE_DIR}/config/RibbonDFConfig.cmake)

    set(CMAKE_SYSTEM_NAME "${CONFIG_SYSTEM_NAME}")
    set(CMAKE_SYSTEM_PROCESSOR "${CONFIG_SYSTEM_PROCESSOR}")
    set(CMAKE_C_COMPILER "${CONFIG_TOOL_CHAIN_PREFIX}${CONFIG_C_COMPILER}")
    set(CMAKE_CXX_COMPILER "${CONFIG_TOOL_CHAIN_PREFIX}${CONFIG_CXX_COMPILER}")
    set(CMAKE_C_FLAGS "${CONFIG_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CONFIG_CXX_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS "${CONFIG_LD_FLAGS}")
    add_definitions(${PROJECT_DEFINES} "${CONFIG_PROJECT_DEFINES}")
    set(CMAKE_INSTALL_PREFIX "${PROJECT_SOURCE_DIR}/install" CACHE PATH "Install path" FORCE)

    if(${CONFIG_PROJECT_DEBUG})
        set(CMAKE_BUILD_TYPE Debug)
    else()
        set(CMAKE_BUILD_TYPE Release)
    endif()

    message("Project Config")
    message(STATUS "Project System Name: ${CMAKE_SYSTEM_NAME}")
    message(STATUS "Project System Processor: ${CMAKE_SYSTEM_PROCESSOR}")
    message(STATUS "Project C_COMPILER: ${CMAKE_C_COMPILER}")
    message(STATUS "Project CXX_COMPILER: ${CMAKE_CXX_COMPILER}")
    message(STATUS "Project CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
    message(STATUS "Project CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")
    message(STATUS "Project CMAKE_EXE_LINKER_FLAGS: ${CMAKE_EXE_LINKER_FLAGS}")
    message(STATUS "Project Build Type: ${CMAKE_BUILD_TYPE}")
    message(STATUS "Project Install Path: ${CMAKE_INSTALL_PREFIX}")

    # message(STATUS "Project Defines: ${PROJECT_DEFINES}")
endmacro()

function(PythonCheck)
    find_package(Python 3.8 REQUIRED)

    if(NOT Python_FOUND)
        message(FATAL_ERROR "Python 3.8 or higher is required")
    endif()
endfunction()

function(DependentsCheck)
    message("Dependents Check")
    PythonCheck()
endfunction()

function(VariablesCheck)
    if(DEFINED RibbonBuildPath AND NOT RibbonBuildPath STREQUAL "")
        # 将RibbonBuildPath转换为绝对路径
        get_filename_component(RibbonBuildPath "${RibbonBuildPath}" ABSOLUTE)
        message(STATUS "RibbonBuildPath: ${RibbonBuildPath}")
    else()
        message(FATAL_ERROR "RibbonBuildPath not defined or empty")
    endif()

    if(DEFINED RibbonComponentsPath AND NOT RibbonComponentsPath STREQUAL "")
        # 将RibbonComponentsPath里的每一个成员转换为绝对路径
        set(RibbonComponentsPathNew "")

        foreach(path ${RibbonComponentsPath})
            get_filename_component(path "${path}" ABSOLUTE)
            list(APPEND RibbonComponentsPathNew ${path})
        endforeach()

        set(RibbonComponentsPath ${RibbonComponentsPathNew} PARENT_SCOPE)
        message(STATUS "RibbonComponentsPath: ${RibbonComponentsPathNew}")
    else()
        message(FATAL_ERROR "RibbonComponentsPath not defined or empty, you must have at least one component directory")
    endif()
endfunction()

macro(ProjectSetup)
    get_filename_component(PROJECT_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME_WE "Project name")
    get_filename_component(PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} ABSOLUTE "Project Path")

    # 参数检查()
    VariablesCheck()

    # 依赖检查
    DependentsCheck()

    # 配置Kconfig
    KconfigSetup()

    # 配置项目
    ConfigProject()
endmacro(ProjectSetup)

ProjectSetup()