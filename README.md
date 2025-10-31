# CHORE ENGINE v1.4
Godot 4.4+ Framework
---

What does this engine do?

It's a basic framework for any kind of game using GDScript.

You provide the game scenes (Control/2D/3D) and Chore provides a scene/menu management framework with libraries/audio/etc. Chore considers your game to be a bunch of scenes with menus on top!

The repository includes a demo project.

---
SHARED DIRECTORIES
---

Copy or use by linking/copying into your project these directories:
- engine
- widgets

Example (copy/link): 
- cp -r /path/to/chore/engine /path/to/yourgame/.
- ln -s /path/to/chore/engine /path/to/yourgame/.

"widgets" contains optional convenient components you can use or not. Even though the Chore repo contains art, sound, etc, you should not link those, they are examples. This means the repository is both the engine *and* the demo project.

---
SETTINGS FILES + DIRECTORIES
---

You will also want to copy+edit these files:
- core/game.gd
- core/settings.gd
- core/dev.gd
You don't have to put them in 'core' directory, but you will need to have these three global variables for autoload. Don't worry too much if you have a conflict, Godot is clever enough to distinguish files with the same names (as you can see in the demo app, there is also a menu called "settings.gd").

You will want to manually create these directories (or equivalent):
- art
- menus
- scenes (or levels?)
- music
Name them anything you want, and let Chore know your directories in "settings.gd"

---
PROJECT SETTINGS
---

You can quickly copy and paste from within your "project.godot" file by opening the Chore sample project and your new project and copying the autoload/input sections.

You will need to set in your Project Settings:
- main scene: launch.tscn (see next section)

Autoload globals (order is important):
- engine/debug.gd / debug
- engine/math.gd / math
- engine/util.gd / util
- your-copy/settings.gd / settings
- your-copy/game.gd / game
- your-copy/dev.gd / dev
- engine/audio.tscn / audio
- engine/root.tscn / root
- engine/menus.gd / menus
- engine/scenes.gd / scenes

---
MAIN SCENE - launch.tscn
---
It's recommended to start a "dummy" scene, that is used to launch into your game. A sample is provided called "launch.tscn" with script "launch.gd". Simply copy "launch.tscn" to your own directory, and link/copy the "launch.gd" script.

Set that as your starting menu in Project Settings -> Application -> Run -> Main Scene

The launch scene allows you to use the "dev.gd" file for quicker development without changing your release. For example you can easily jump to a scene by modifying "dev.launch_scene_override", and that won't happen in your release builds. The Godot editor auto-opens the main scene when you load your project. It is better for everyone if your first scene is your own scene and not Chore's.

---
MENUS + SCENES
---
Internally, all scenes and menus are called scenes, but there is also a "menus" helper class that treats some scenes as menus.

- Menus = overlaid stack of many-visible scenes (first-in-last-out)
- Scenes = one-at-a-time-visible pool of scenes

Menus are displayed on top of scenes.

So for example you can have your game level, then add some menus on top and still see the game paused underneath.

- menus.show('your-menu') to add a menu to the root scene
- scenes.show('your-scene') to easily add a persistent level (just a menu) to root scene

See the demo app included for examples on how to use these.

---
TRANSITIONS
---
You may also use fade transitions without switching scenes, just call one and yield after.
For example if you are making a storybook scene and you want fades between panels.

---
BASE CLASS / DUCKING
---
There is a top-level class "menu.gd" provided as reference for your menus/scenes, but it isn't required to inherit from. You just add any Control or Node as a scene/menu. This approach was chosen because it would be a *chore* to make all your scenes inherit from this.

Instead, ducking is preferred:
- on_show(), on_hide(), on_pause(), on_resume(), notify_closing(), pass_data()

Add these optional methods to your scene/menu if you need special code during these moments.

---
CANVAS LAYERS
---
You need to be aware of any Canvas layers being higher than the root overlay canvas layer. You can change that in settings.gd. 

---
COMPLEX MENUS
---
Your game may end up having more complex menus than Chore expects, for example in an RPG or digital boardgame app. In that case you should only use Chore for two primary levels: the game world (scenes) and the main menus (menus), and consider the submenus as part of your game world, then use a traditional Godot approach to add further submenus. You can also use the HUD interface (root.add_hud, etc) to add items that stay on top of scenes but below menus, but for most control you are going to want to add complex submenus as instantiated popups inside of a world scene, and then keep the 'menus' manager for traditional higher level main menus (like: new game, restart, save/load, settings, quit, etc). Besides, dealing with the callback logic and data handling from complex submenus would be more burdensome with Chore, and Chore Engine wants to reduce your chores, not increase them.

---
FUTURE PLANS
---
- Deprecate some global names, such as "game", and put them into a "chore" object, so as not to conflict less with peoples projects, because you probably have a "game" class?
- Rename util/math/debug/etc to chore_util/chore_math/etc to avoid potential conflicts?
- Rename ducking calls to on_chore_show() etc?
- Improve code to Godot standards: more static typing, private variables, etc.
- Abstract scenes/menus into a single manager object so you can add as many managers as needed.

---
DEVELOPMENT MODE
---

Enable development mode with:
- create file dev.tmp "ex: touch dev.tmp" in your project root
- ensure 'dev.tmp' doesn't get included in your builds (it shouldn't by default)
- set "game.release = false"
- edit dev settings in "dev.gd"

General Hotkeys:
- ui_screenshot - F5
- ui_fullscreen - F11

Dev Hotkeys:
- ui_quit - Q (useful for exiting fast + gracefully)
- ui_hud - H (hide/show hud, useful when taking screenshots)
- dev_autoscreenshot - A (useful for making GIFs)
- dev_console - ` (Tilda, left of 1)
- dev_pause - P
- dev_advance - \ (Backslash)
- dev_resume - Backspace
- dev_slow - [ (run slower)
- dev_fast - ] (run faster)

You'll need to add these to your project's Input Map to use them.

The debug console currently doesn't support typing, but it can be printed to.

---
GODOT GAMES USING CHORE ENGINE
---
- Dirty Land - www.dirtylandgame.com
- Forehead Chip - www.foreheadchip.com
- Shade Protocol - www.shadeprotocolgame.com


