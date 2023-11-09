
function config-osx-install-json()
{
	# command line-based JSON viewer 
	# https://github.com/antonmedv/fx
	brew install fx
}


function config-osx-install-tools()
{
	config-osx-install-json

	# Git
	brew install git-delta
	brew install grv

	# Basic CMD Tools
	# to use strftime with awk
	brew install gawk
	# gshuf
	brew install coreutils
}

function config-osx-zsh()
{

	brew install --cask font-hack-nerd-font
	brew install --cask font-hack-nerd-font
}

function config-osx-install-tessaract()
{
	brew install tesseract
}

function config-osx-install-resource-managers()
{
	brew install btop
	brew install bmon
	
	# btm
	brew install bottom
}

function config-osx-install-docker-tools()
{
	npm install -g dockly
}

function config-osx-install-network-tools()
{
	brew install gping
}
