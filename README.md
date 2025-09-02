![preview](https://github.com/freddidit/bettercompile/blob/master/preview.png)

## Usage

### Command
- ``
:Compile
``
- ``
Compile command:  
``
- ``
Compile command: cc hello_world.c -o hello_world
``

### Keybinds
These only apply to the compilation buffer opened by the command.

| Letter    | Action                                         |
|-----------|------------------------------------------------|
| o         | Move to next file                              |
| O         | Move to previous file                          |
| x         | Open original file                             |
| X         | Close compilation buffer & Open original file  |
| r         | Re-run compilation command                     |

## Manual Installation (Unix)
Given how minimal this plugin is, I don't believe package manager support is necessary as of now.

``
$ mkdir -p ~/.config/nvim/plugin/ && curl --output ~/.config/nvim/plugin/bettercompile.lua https://raw.githubusercontent.com/freddidit/bettercompile/refs/heads/master/bettercompile.lua
``

## About
``bettercompile`` is my solution to the problem of the inconvenient compilation process of Neovim.

Similarly to Emacs, the compile command opens a scratch buffer, pipes the output of the compilation command into said buffer, parses the output looking for files, highlights the found files, and creates the navigation keybinds.

## Contributing
You can contribute to the project in several ways.
- By submitting more lua patterns for file detection.
- By discovering and reporting bugs.
- By implementing tests and more examples.
- By contributing to the code itself.

Any help is appreciated.
