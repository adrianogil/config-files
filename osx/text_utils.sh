# OSX - text utils

alias c="code"
alias cw="code -n"

function _clipboard-system-set()
{
    pbcopy
}

function _clipboard-system-image-get()
{
    local output_file=$1

    if command -v pngpaste >/dev/null 2>&1
    then
        pngpaste "${output_file}"
        return $?
    fi

    if ! command -v swift >/dev/null 2>&1
    then
        printf '_clipboard-system-image-get: install pngpaste or the Xcode Command Line Tools\n' >&2
        return 127
    fi

    swift - "${output_file}" <<'SWIFT'
import AppKit
import Foundation

let outputPath = CommandLine.arguments[1]
guard let image = NSImage(pasteboard: NSPasteboard.general),
      let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("The clipboard does not contain an image.\n", stderr)
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: outputPath))
} catch {
    fputs("Could not write PNG: \(error)\n", stderr)
    exit(1)
}
SWIFT
}

alias paste-text-from-clipboard="pbpaste"

function tg()
{
    # Create new file and add it to git
    new_file=$1

    file_directory=$(dirname ${new_file})
    mkdir -p ${file_directory}

    touch ${new_file}
    git add ${new_file}
}

function cg()
{
    # Open new file into vscode and add it to git
    new_file=$1

    tg ${new_file}
    code ${new_file}
}
