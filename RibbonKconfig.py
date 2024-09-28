import argparse
import os
import shutil
import kconfiglib
from menuconfig import menuconfig


def distclean(project_path):
    shutil.rmtree(os.path.join(project_path, "build"))
    shutil.rmtree(os.path.join(project_path, "config"))
    shutil.rmtree(os.path.join(project_path, "install"))
    os.mkdir(os.path.join(project_path, "build"))
    os.mkdir(os.path.join(project_path, "config"))
    os.mkdir(os.path.join(project_path, "install"))


def write_toolchain_file(project_path, kconf):
    with open(os.path.join(project_path, "build/toolchain.cmake"), "w",) as toolchain_file:
        toolchain_file.write(
            "#generated automatically by RibbonDF_build.py, do not modify it manually\n"
        )

        system_name = [sym.str_value for sym in
                       kconf.unique_defined_syms if sym.name == "SYSTEM_NAME"][0]
        system_processor = [sym.str_value for sym in
                            kconf.unique_defined_syms if sym.name == "SYSTEM_PROCESSOR"][0]
        toolchain_prefix = [sym.str_value for sym in
                            kconf.unique_defined_syms if sym.name == "TOOL_CHAIN_PREFIX"][0]
        c_compiler = [sym.str_value for sym in
                      kconf.unique_defined_syms if sym.name == "C_COMPILER"][0]
        cxx_compiler = [sym.str_value for sym in
                        kconf.unique_defined_syms if sym.name == "CXX_COMPILER"][0]
        asm_compiler = [sym.str_value for sym in
                        kconf.unique_defined_syms if sym.name == "ASM_COMPILER"][0]
        c_flags = [sym.str_value for sym in
                   kconf.unique_defined_syms if sym.name == "C_FLAGS"][0]
        cxx_flags = [sym.str_value for sym in
                     kconf.unique_defined_syms if sym.name == "CXX_FLAGS"][0]
        ld_flags = [sym.str_value for sym in
                    kconf.unique_defined_syms if sym.name == "LD_FLAGS"][0]
        project_defines = [sym.str_value for sym in
                           kconf.unique_defined_syms if sym.name == "PROJECT_DEFINES"][0]
        project_debug = [sym.str_value for sym in
                         kconf.unique_defined_syms if sym.name == "PROJECT_DEBUG"][0]
        project_major_version = [sym.str_value for sym in
                                 kconf.unique_defined_syms if sym.name == "PROJECT_MAJOR_VERSION"][0]
        project_minor_version = [sym.str_value for sym in
                                 kconf.unique_defined_syms if sym.name == "PROJECT_MINOR_VERSION"][0]
        project_patch_version = [sym.str_value for sym in
                                 kconf.unique_defined_syms if sym.name == "PROJECT_PATCH_VERSION"][0]
        toolchain_file.write(
            "set(CMAKE_SYSTEM_NAME \"{0}\")\n".format(system_name))
        toolchain_file.write(
            "set(CMAKE_SYSTEM_PROCESSOR \"{0}\")\n".format(system_processor))
        toolchain_file.write(
            "set(CMAKE_C_COMPILER \"{0}{1}\")\n".format(toolchain_prefix, c_compiler))
        toolchain_file.write(
            "set(CMAKE_CXX_COMPILER \"{0}{1}\")\n".format(toolchain_prefix, cxx_compiler))
        toolchain_file.write(
            "set(CMAKE_ASM_COMPILER \"{0}{1}\")\n".format(toolchain_prefix, asm_compiler))
        # toolchain_file.write(
        #     "set(CMAKE_C_FLAGS \"{0}\")\n".format(c_flags))
        # toolchain_file.write(
        #     "set(CMAKE_CXX_FLAGS \"{0}\")\n".format(cxx_flags))
        # toolchain_file.write(
        #     "set(CMAKE_LD_FLAGS \"{0}\")\n".format(ld_flags))
        # toolchain_file.write(
        #     "set(CONFIG_PROJECT_DEFINES \"{0}\")\n".format(project_defines))
        # toolchain_file.write(
        #     "set(CONFIG_PROJECT_DEBUG \"{0}\")\n".format(project_debug))
        # toolchain_file.write(
        #     "set(CONFIG_PROJECT_MAJOR_VERSION \"{0}\")\n".format(project_major_version))
        # toolchain_file.write(
        #     "set(CONFIG_PROJECT_MINOR_VERSION \"{0}\")\n".format(project_minor_version))
        # toolchain_file.write(
        #     "set(CONFIG_PROJECT_PATCH_VERSION \"{0}\")\n".format(project_patch_version))


def write_cmake_setting(project_path, kconf):
    # 遍历所有选项和配置
    define_list = []

    with open(os.path.join(project_path, "config/RibbonDFConfig.cmake"), "w",) as cmake_file:
        cmake_file.write(
            "#generated automatically by RibbonDF_build.py, do not modify it manually\n"
        )
        for sym in kconf.unique_defined_syms:
            if sym.type == kconfiglib.BOOL:
                cmake_value = "on" if sym.str_value == "y" else "off"
                define_value = 1 if sym.str_value == "y" else 0
                define_name = "-DCONFIG_" + sym.name + "=" + str(define_value)
                define_list.append(define_name)
            elif sym.type == kconfiglib.STRING:
                cmake_value = '"' + sym.str_value + '"'
                define_value = '"' + sym.str_value + '"'
                define_name = "-DCONFIG_" + sym.name + "=" + define_value
                define_list.append(define_name)
            elif sym.type == kconfiglib.INT:
                cmake_value = sym.str_value
                define_value = int(sym.str_value)
                define_name = "-DCONFIG_" + sym.name + "=" + str(define_value)
                define_list.append(define_name)

            # 生成CMake设置
            cmake_setting = "set(CONFIG_{0} {1})\n".format(
                sym.name, cmake_value)
            cmake_file.write(cmake_setting)

        define_str = " ".join(define_list)
        cmake_file.write("set(PROJECT_DEFINES " + define_str + ")\n")


def save_settings(project_path, kconf):
    kconf.write_config(os.path.join(project_path, "config/.config"))
    write_cmake_setting(project_path, kconf)
    write_toolchain_file(project_path, kconf)


def do_menuconfig(project_path):
    kconf = kconfiglib.Kconfig(os.path.join(project_path, "build/Kconfig"))
    kconf.load_config(os.path.join(project_path, "config/.config"))
    menuconfig(kconf)
    save_settings(project_path, kconf)


def kconfig_load(project_path):
    # 如果没有config目录，则创建
    if not os.path.exists(os.path.join(project_path, "config")):
        os.mkdir(os.path.join(project_path, "config"))

    kconf = kconfiglib.Kconfig(os.path.join(project_path, "build/Kconfig"))
    if (not os.path.exists(os.path.join(project_path, "config/.config"))):
        save_settings(project_path, kconf)


def Kconfig_init(project_path, components_path):
    project_kconfig_file = os.path.join(project_path, "build/Kconfig")
    current_path = os.path.dirname(os.path.abspath(__file__))

    with open(project_kconfig_file, "w",) as kconfig_file:
        kconfig_file.write(
            "#generated automatically by RibbonDF_kconfig.py, do not modify it manually\n"
        )
        kconfig_file.write("menu \"project Configuration\"\n")
        kconfig_file.write("source \"" + current_path + "/project.Kconfig\"\n")
        kconfig_file.write("endmenu\n")

        for component_path in components_path:
            component_name = os.path.basename(component_path)
            kconfig_file.write("menu \"" + component_name +
                               " Configuration\"\n")
            kconfig_file.write(
                "osource \"" + component_path + "/*/Kconfig\"\n")
            kconfig_file.write("endmenu\n")


def project_init(project_path, components_path):
    Kconfig_init(project_path, components_path)
    kconfig_load(project_path)

# @brief 解析命令行参数
# @return 命令行参数对象


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--distclean", action="store", help="distclean")
    parser.add_argument(
        "-m", "--menuconfig", action="store", help="检查当前路径下的模块列表"
    )
    parser.add_argument(
        "-i",
        "--project_init",
        type=str,
        help="输出项目路径，和注册模块路径",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    if args.distclean:
        distclean(args.distclean)
    elif args.project_init:
        init_args = args.project_init.split(";")
        project_path = init_args[0]
        components_path = init_args[1:]
        project_init(project_path, components_path)
    elif args.menuconfig:
        do_menuconfig(args.menuconfig)
    else:
        print("未知命令")

    exit(0)
