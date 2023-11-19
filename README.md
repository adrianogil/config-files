# config-files
A set of small utilities functions that I find useful

## Target OS
Most of functions should work on Linux, OSX and Termux

## How to Install
On terminal, just export a variable 'CONFIG_FILES_DIR' with the path of this project.

```
export CONFIG_FILES_DIR=<path-to-config-files>
source $CONFIG_FILES_DIR/bashrc.sh
```

You can also use [gil-install](https://github.com/adrianogil/gil-tools/blob/master/src/python/gil_install.py)
```
cd <path-to-config-files>
gil-install -i
```

## Commands

### config-fz

The `config-fz` function is a utility that allows you to run a command from the ConfigFiles using a fuzzy finder for selection. 
This function is particularly useful when you need to quickly find and execute a command from the ConfigFiles without having to remember the exact command or navigate through the directories.

## Contributing

Feel free to submit PRs. I will do my best to review and merge them if I consider them essential.

## See also

- https://github.com/adrianogil/gil-tools
- https://github.com/adrianogil/dotfiles