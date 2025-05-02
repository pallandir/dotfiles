<a name="readme-top">
</a> <br /> 
<div align="center"> 
    <a href="#"> 
        <img src="./assets/ubuntu.svg" alt="Logo" width="80" height="80"> 
    </a> 
    <h3 align="center">GNOME config (Ubuntu)</h3>
  <p align="center">
    Setup GNOME theme and extensions to work on a good looking practical system.
    <br />
    <br />
    <a href="https://github.com/pallandir/dotfiles/issues">Report Bug</a>
    ·
    <a href="https://github.com/pallandir/dotfiles/issues">Request Feature</a>
  </p>
</div>
<br/>
<br/>
<img align="center" src="./assets/preview.jpg" alt="preview">

## About this repository

This repository contains all dotfiles used to configure GNOME applications on Ubuntu. 
It provides themes for `GTK-3` and `GTK-4`, `Flatpack` and some 'good' extensions to install.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

> Note: For GTK-3.0 simply copy the theme folder. For GTK-4.0 copy the content of the theme folder.
You may also need to restart all your apps for your theme to apply

### GTK Themes

- Copy the content of `GTK-3.0` into ~/.config/gtk-3.0/ 
- Copy the content of `GTK-4.0` into ~/.config/gtk-4.0/

### Flatpack and Shell Themes

- Add `catppuccin-theme` to your ~/.theme folder. If you don't have any theme folder just create it `mkdir -p .theme` in /home/
- run `sudo flatpak override --filesystem=$HOME/.themes` and `sudo flatpak override --env=GTK_THEME=Catppuccin-GnomeTheme`

This will apply theme for your Flatpack apps. 

To apply theme for your shell use [Gnome tweak](https://docs.rockylinux.org/desktop/gnome/gnome-tweaks/) and select the desired theme in appearance. For your shell background you can use the color: `202032`. 

### Extensions Manager

The [extensions manager](https://github.com/mjakeman/extension-manager) allow you to install GNOME extensions for your system. Here are some that can be useful.

- [Space bar](https://github.com/christopher-l/space-bar) will allow you to define workspaces from your top bar.
- [Arc Menu](https://github.com/fishears/Arc-Menu) will allow you to launch apps from your top bar.
- [Clipboard mananger](https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator) will give you access to your system clipboard content.
- [Emoji copy](https://github.com/FelipeFTN/Emoji-Copy) will add emoji in top bar.

### ZSH

ZSH can replace the default shell. 
Here are instructions to install it: [setup zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)
All required plugins are listed in the `.zshrc` file. 
Theme used is [jovial](https://github.com/zthxxx/jovial) (pretty useful for git)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## License

Distributed under the `GNU General Public License v3.0` License.  

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Acknowledgments

Thanks to these great resources:

- [Wallapapers](https://github.com/orangci/walls-catppuccin-mocha)
- [Catppuccin](https://github.com/catppuccin)
- [Catppuccin palette](https://catppuccin.com/palette/)
- [ZSH](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)
- [Jovial ZSH theme](https://github.com/zthxxx/jovial)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
