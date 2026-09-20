# Friday Night Funkin' Pico Engine
![FNFModBanner](art/banner.png)
<div align='center'>
<table>
  <tr>
    <td><img src="docs/readme_images/TitleCard-pico.gif" alt="Title Screen" width="350"/></td>
    <td><img src="docs/readme_images/Menu-pico.png" alt="Main Menu" width="350"/></td>
  </tr>
</table>
</div>
<p align="center"><img src="https://img.shields.io/badge/-HAXE-262626.svg?logo=haxe&style=for-the-badge">

# You can also play this title at the following links
- [Gamebana](https://gamebanana.com/tools/22943)
- [GameJolt](https://gamejolt.com/games/funkin-engine/948902)
- [itch.io (Legacy Build)](https://lucas-sanches.itch.io/funkin-pico)

# About
This project is a custom [Friday Night Funkin'](https://github.com/FunkinCrew/Funkin) engine based on [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) developed with a primary focus on delivering an optimized experience for creating Pico-centered mods.

The engine preserves the core structure of Psych Engine while introducing custom systems and internal tweaks to support Pico as a fully playable character. This includes animation handling, gameplay mechanics, and character-specific features.

The main goal of this project is to provide modders with an engine that simplifies the creation of Pico-centered mods, without sacrificing the flexibility, stability, and features of the original Psych Engine

# Installation
[View The Build from Engine](/docs/BUILDING.md)

# Customization
If you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can refer to the `Project.xml` file.
Inside `Project.xml`, you will find several variables to customize Psych Engine to your liking.
To start you off, disabling *Video Cutscenes* should be simple, simply delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this: `<!-- YOUR_LINE_HERE -->`
Same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file.

- Use `PICO_ALLOWED` for things via Source Code
- Use `PSYCH_ALLOWED` for general Psych Engine stuff
- Use `VSLICE_ALLOWED` if you want to adapt something from the FNF Base Game

# Credits
* Pico Engine: Lucas Sanches
* Friday Night Funkin': [Ninjamuffin99](https://x.com/ninja_muffin99),[PhantomArcade](https://x.com/PhantomArcade3K),[KawaiSprite](https://x.com/kawaisprite),and Evilsk8r
* Resource and Engines used: ([Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine)/[Psych Plus Team](https://github.com/Psych-Plus-Team)/[P Slice Team](https://github.com/Psych-Slice/P-Slice))

# 💖 Support
If you enjoy this project and would like to support its development, here are some ways you can help:

- **[GitHub Sponsors](https://github.com/sponsors/Lucas62944)** - Support the development directly on GitHub
- **[itch.io](https://lucas-sanches.itch.io/funkin-pico)** - Play and support the game on itch.io
- Every contribution helps keep this project alive and enables us to add more features and improvements!
-----
<p align="center"><a href="#readme-top">Back To Top</a></p>
