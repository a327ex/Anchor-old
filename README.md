# Anchor

Anchor is a Lua/MoonScript game development engine built on top of LÖVE. Its goal is to serve as a good engine for programmers who like Lua, are mostly developing 2D games, and want to release their games on Steam and on the Web. It's currently being built so use at your own peril!

<br>

## Distributing Your Games

### Windows

To build your game for Windows simply navigate to the `engine/love` folder with your terminal and then call `build_windows.bat GAMENAME`. This will package your game up for distribution into a .zip file located in `builds/windows`.

### Web

Building your game for the web is a little more involved but here are the steps:

1. Set `web = true` at the top of your `main.lua` file before you require the engine

2. Change window width and height in `conf.lua` to the size you want your game to be, as well any scaling variables like `sx, sy` in `engine/init.lua`

3. Install love.js somewhere on your computer as described in [this page](https://github.com/Davidobot/love.js). You simply need to download that folder, `cd` into it and then call `npm install` and `npm link`.

4. Call `build_web.bat GAMENAME GAMEFOLDER` where `GAMEFOLDER` is the complete path to your game. For instance, if my project was located in `e:\a327ex\JUGGLRX` I would call `build_web.bat JUGGLRX e:\a327ex\JUGGLRX`.

The build should be available in the `builds/web` folder and you can test it by `cd`ing into it, running `python -m http.server 8000` and then opening `localhost:8000` in your browser.

If you're making your game available on a site like itch.io, then editing the `index.html` file also is needed to make it work. There you should change the canvas resolution to your game's resolution, as well as removing both titles and footers from the file. You also need to set the size of the display window on itch.io to match the game's resolution.

*Notes: you need to be mindful of the restrictions that [love.js](https://github.com/Davidobot/love.js) has in regards to the Web. Those are described in that github page as well as [here](https://schellingb.github.io/LoveWebBuilder/). Most of them have already been taken care of in the engine when you set the global `web` variable to true, but in case your game fails to run, check to see if your code isn't doing any of things mentioned in either page. It's important to also notice that only the web build uses `conf.lua`, while the Windows one uses all the settings passed on to the `engine_run` function directly.*


<br>

## Game Examples w/ Source Code

### JUGGLRX prototype

A prototype I made in 4 days written in MoonScript. It's called JUGGLRX and it's about juggling as many balls as possible without dying!

**[[Play](https://a327ex.itch.io/jugglrx-prototype)]** **[[Source](https://github.com/a327ex/JUGGLRX-prototype)]** *(click image below to watch a gameplay video)*

<p align="center">
<a href="https://www.youtube.com/watch?v=cYXj8AP2kJ0"><img src="https://i.imgur.com/4hVutyx.png"></a>
</p>
