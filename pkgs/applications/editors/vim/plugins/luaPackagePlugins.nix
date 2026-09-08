/*
  pkgs/applications/editors/vim/plugins/luaPackagePlugins.nix is an auto-generated file -- DO NOT EDIT!
  Regenerate it with: nix run nixpkgs#luarocks-packages-updater
  Mark packages in maintainers/scripts/luarocks-packages.csv with neovim=true to expose them as Vim plugins.
*/
{
  lib,
  buildNeovimPlugin,
  neovim-unwrapped,
}:
final: prev:
let
  luaPackages = neovim-unwrapped.lua.pkgs;

  luarocksPackageNames = [
    "canola-nvim"
    "fidget-nvim"
    "fzf-lua"
    "gitsigns-nvim"
    "grug-far-nvim"
    "haskell-tools-nvim"
    "image-nvim"
    "kulala-nvim"
    "lsp-progress-nvim"
    "lualine-nvim"
    "luasnip"
    "lush-nvim"
    "lz-n"
    "lze"
    "lzextras"
    "lzn-auto-require"
    "middleclass"
    "mini-test"
    "neorg"
    "neorg-interim-ls"
    "neotest"
    "neotest-nix"
    "nui-nvim"
    "nvim-cmp"
    "nvim-nio"
    "nvim-web-devicons"
    "oil-nvim"
    "orgmode"
    "papis-nvim"
    "plenary-nvim"
    "rest-nvim"
    "rocks-config-nvim"
    "rocks-dev-nvim"
    "rocks-git-nvim"
    "rocks-lazy-nvim"
    "rocks-nvim"
    "rtp-nvim"
    "rustaceanvim"
    "telescope-manix"
    "telescope-nvim"
  ];
in
lib.genAttrs luarocksPackageNames (
  name:
  buildNeovimPlugin {
    luaAttr = luaPackages.${name};
  }
)
