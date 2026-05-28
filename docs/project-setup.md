# Project Tooling Guide

There are specific tools you will need to set up your dev environment.

## Required VSCode Extensions

You will need these plugins installed:

- [Luau Language Server](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp)
- [StyLua](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua)
- [Rojo](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo)
- [Selene](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua)

## Project Configuration

### Node

Ensure you have [Node.js](https://nodejs.org/en) and run this command once:

```bash
npm install
```

### rokit

Open **PowerShell** and run the following command (this will install rokit on your device, you may need to restart):

```PowerShell
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
```

If something goes wrong with that, go [here](https://github.com/rojo-rbx/rokit/releases/tag/v1.2.0) and install rokit on your device.

Then, once you have Rokit installed, run:

```bash
rokit install
```

### Settings

You will need to add some settings to your VSCode. Make a folder called `.vscode` on the root of the project, then make a file under it called `settings.json`. Your `settings.json` should look like this:

```JSON
{
    "stylua.configPath": "stylua.toml",
    "editor.formatOnSave": true,

    "luau-lsp.completion.imports.requireStyle": "alwaysAbsolute",
    "luau-lsp.completion.imports.suggestRequires": false,
    "luau-lsp.completion.fillCallArguments": false,
    "luau-lsp.completion.imports.enabled": true,
    "luau-lsp.sourcemap.autogenerate": true,
    "luau-lsp.completion.enabled": true,

    "[luau]": {
        "editor.defaultFormatter": "JohnnyMorganz.stylua",
        "editor.formatOnSave": true,
    },

    "stylua.targetReleaseVersion": "latest"
}
```

### Private Directories

Create a folder called "testing" on the root, with a "client" and a "server" folder under it. It should look like this:

### Running the Dev Environment

To start the development pipeline, run **Rojo** by doing:

```console
rojo serve
```

Go to studio, connect, and start coding! If you need to reinstall your packages or update their typechecking/intellisense, run:

```console
npm run wally
```

This will install all **wally** packages, and update them with **wally-package-types**.
