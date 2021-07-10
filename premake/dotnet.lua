newoption {
    trigger = "python-command",
    value = "CMD",
    description = "The python interpreter command name/path",
    default = "python"
}
function dotnet_project(path)
    kind "Utility"
    files {
        (path)
    }
    filter "files:**.*proj"
        buildmessage "Compiling .NET Core project: %{file.basename}"
        buildcommands {
            'dotnet build "%{!file.abspath}" -o "%{cfg.targetdir}"'
        }
        buildoutputs { "%{cfg.targetdir}/%{file.basename}.dll" } -- .NET Core always outputs DLLs
end
function generate_csharp_project(directory_path, name, template, definitions, references, rootdir, scriptdir)
    local abs_rootdir = path.getabsolute(path.join(scriptdir, rootdir))
    print(abs_rootdir)
    local abs_directory = path.getabsolute(path.join(abs_rootdir, directory_path))
    python_command = _OPTIONS["python-command"]
    local command = 'bash -c "cd ' .. abs_rootdir .. ' && \\"' .. python_command .. '\\" -m scripts create-dotnet-project \\"' .. name .. '\\" \\"' .. abs_directory .. '\\" \\"' .. template .. '\\"'
    for index in pairs(definitions) do
        local definition = definitions[index]
        print("Adding definition: " .. definition)
        command = command .. ' -d \\"' .. definition .. '\\"'
    end
    for index in pairs(references) do
        local ref = path.getabsolute(path.join(scriptdir, references[index]))
        print("Adding reference: " .. ref)
        command = command .. ' -r \\"' .. ref .. '\\"'
    end
    command = command .. '"'
    print(command)
    os.execute(command) 
    return path.join(abs_directory, name) .. ".csproj"
end