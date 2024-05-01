# GZDoom Ladder

This ZScript mapper's resource offers a Source-engine-styled ladder for easy placement of climbable ladders in your maps.

### Features

This library/resource offers a dedicated class, `FuncLadder`, that can be placed in your maps to create a ladder collision box. The player can approach this object from any point and will be attached to the ladder, after which they will be able to move up and down the ladder with movement keys (including Jump/Swim up/Fly up and Swim down/Fly down), press Use to detach from it and press Use again to grab it again while falling next to it.

The library also comes with 3 classes to handle the visuals and some 3D models in the OBJ format attached to them.

The library also comes with an example map called `ladder_example` (see maps/ladder_example.wad). You can open it in GZDoom by loading the archive and typing `map ladder_example` in the console, or open it in Ultimate Doom Builder to check how it works. This map is not requires to be able to use the library.

#### Included classes

* `FuncLadder`: A ZScript class that handles the actual ladder collision and movement. Lets the player get attached to the ladder by walking or jumping into it.
  Editor number: 16100

* `LadderObjectMid`: This is a visual object with an attached 3D model of a ladder. The model is 64 units tall and will automatically adjust to the game's pixelratio (by default it uses Z scaling of 1.2, to match the default Doom pixelratio). Stack as many as you like
  Editor number: 16101

* `LadderObjectTop`: Like LadderObjectMid, except this one is meant to be used at the top of the ladder, to make it more visible. 32 units tall.
  Editor number: 16102

* `LadderObjectAuto`: This object will automatically spawn the necessary number of ladder models for you. Just specify the total ladder height in its parameters.
  Editor number: 16103

Note: the included 3D models don't come with their own textures, instead they're set up to use textures from doom2.wad. Specifically, the textures named METAL2 and MIDBARS.

### How to use

1. Make sure your map is in the UDMF format and you're using Ultimate Doom Builder. Make sure **gzdoom.pk3** is attached as a resource in **Map Options** (otherwise ZScript classes won't be visible) and the "Exclude from testing parameters" checkbox is checked next to it.

2. Copy-paste the contents of this library into your PK3 or add them as a resource in UDB.

3. Create visuals for your ladder. (You can use the LadderObjectMid and LadderObjectTop or LadderObjectAuto objects if you like, but this is not required.)

4. Place **FuncLadder** in front of your ladder, **facing away** from it. The angle is important, since it will determine which way the player can or cannot move when approaching the ladder from above or below.

5. Right-click **FuncLadder**, open the **Action / Tag / Misc.** Adjust the ladder's Radius to match half of its intended width, Height to match the desired height, and the **Top climb protection** and **Drop protection** options as desired (both are enabled by defualt).

#### FuncLadder parameters

* **Top climb protection**: If enabled, this circumvents one of the more annoying features of the actual Source ladders: the player won't have to carefully position themselves when dropping onto the ladder from above. Just walk into it! The protection won't let the player move past it and drop down unless they explicitly jump over it.
  
  This is only relevant for levels with falling damage, so this can be disabled.

* **Drop protection**: The player can drop from the ladder at any point by pressing Use. If this option is enabled, when they do that, their horizontal momentum will be nullified, guaranteeing that they won't be able to immediately fly away from the ladder. If disabled, they can hold movement keys while pressing Use to immediately be moved away from the ladder.

#### Ladder object auto

This object offers an easy way to spawn multiple ladder models without having to actually place and adjust them in the editor. It's recommended to use it when creating tall ladders. The object must be placed next to a wall, so its *middle* is slightly outside the wall, and it should be facing *away* from the wall.

On its **Action / Tag / Misc.** you'll find the following arguments:

* **Total ladder height**: Input the total desired height of the ladder in map units. Note, the spawned models will be automatically scaled to the desired height even if that height is not in 64-unit increments. So, for example, if you input the height of 300, it'll spawn 4 LadderObjectMid objects, each scaled to ~1.172, so they fill the desired height.

* **Spawn top model**: Whether spawn LadderObjectTop at the top end of the ladder.
