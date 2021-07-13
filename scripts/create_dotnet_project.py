# creates a .NET Core C# project from the specified settings
import subprocess
import platform
import xml.etree.ElementTree as et
import argparse
import os, os.path
class Element:
    def __init__(self, tag: str, text: str = None):
        self.tag = tag
        self.text = text or ""
    def copy_text_from_list(self, list: list[str]):
        self.text = ""
        for index in range(len(list)):
            element = list[index]
            if index != 0:
                self.text += ";"
            self.text += element
class ElementSpec:
    def __init__(self, definitions: list[str]):
        self.elements = list[Element]()
        self.add("LangVersion").text = "9.0"
        self.add("Nullable").text = "enable"
        self.add("AllowUnsafeBlocks").text = "true"
        self.add("DefineConstants").copy_text_from_list(definitions or [])
    def add(self, tag: str):
        spec = Element(tag)
        self.elements.append(spec)
        return spec
def add_defs(path: str, defs: list[str]) -> int:
    tree = et.parse(path)
    root = tree.getroot()
    prop_group: et.Element = root.find("PropertyGroup")
    if not prop_group:
        print("Could not find a PropertyGroup element!")
        return 1
    spec = ElementSpec(defs)
    for element in spec.elements:
        xml_element = et.SubElement(prop_group, element.tag)
        xml_element.text = element.text
    tree.write(path)
    return 0
def cleanup_console(directory: str):
    pass
def cleanup_classlib(directory: str):
    os.unlink(os.path.join(directory, "Class1.cs"))
def run(args: list[str]) -> int:
    if platform.system() == "Windows":
        print("This script should not be run on windows!")
        return 1
    argparser = argparse.ArgumentParser(prog="scripts create-dotnet-project", description="Generates a .NET Core project")
    argparser.add_argument("name", type=str, help="The name of the project to generate")
    argparser.add_argument("directory", type=str, help="The output directory")
    argparser.add_argument("template", type=str, help="The .NET Core template to generate from")
    argparser.add_argument("-d", "--define", action="append", help="Adds a \"DefineConstants\" entry")
    argparser.add_argument("-r", "--reference", action="append", help="Adds a project to the reference list")
    argparser.add_argument("-p", "--package", action="append", help="Adds a NuGet package to the reference list")
    parsed_args = argparser.parse_args(args)
    return_value = subprocess.call(["/usr/bin/env", "dotnet", "new", parsed_args.template, "-n", parsed_args.name, "-o", parsed_args.directory, "--force"])
    if return_value != 0:
        return return_value
    cleanup_table = {
        "console": cleanup_console,
        "classlib": cleanup_classlib
    }
    try:
        cleanup_table[parsed_args.template](parsed_args.directory)
    except KeyError:
        print("This template is currently not supported!")
        return 1
    project_location = os.path.join(parsed_args.directory, parsed_args.name) + ".csproj"
    for name in parsed_args.reference or list[str]():
        return_value = subprocess.call(["/usr/bin/env", "dotnet", "add", project_location, "reference", name])
        if return_value != 0:
            return return_value
    for name in parsed_args.package or list[str]():
        return_value = subprocess.call(["/usr/bin/env", "dotnet", "add", project_location, "package", name])
        if return_value != 0:
            return return_value
    return add_defs(project_location, parsed_args.define)