# Windup Wizards

## General

Everything in the level can be wound-up. When released, they'll do whatever they're supposed to do. (Rotate, walk ahead, jump, etc.)

So there are three decisions:

-   Which ones you actually use.

-   When you release them

-   How *much* you power them up. (For each time/power level, they do their action *once*.)

If it's turn-based:

-   Each turn you can either *move* or *wind-up something*.

-   **Alternative:** everything that can be wound-up, has those pins sticking out. Entering a grid with a pin, will rotate it once.

-   **Even better alternative:** you are a *gust of wind*. All you can do is pick a direction and *fly all the way in that direction*. All pins you pass, though, will be rotated in that direction. (Either winding them up positively or negatively.)

If it's real-time (a platformer or something):

-   Movement, Jumping, Wind-up

-   Whenever there's something in front of you (that can be wound-up), it will be highlighted, and a prompt to press the button appears. Doing so will wind it once.

Or there's a general semblance of "energy" (you start with/can get over time). Each time you wind-up something, it takes 1 Energy.

**IDEA:** This picture of a *cat* chasing a *fake mouse*. You can wind-up the mouse to distract the cat and make it chase after it.

## Goal

The puzzle is filled with "threats" of some sort. Your goal is to eliminate all threats.

## Input

You play a gust of wind.

-   Move in any direction by pressing that key/moving the joystick/swiping.

-   By pressing another key, you can *activate* everything you've wound up.

## Keygen

keytool -v -genkey -keystore windup_wizards.keystore -alias pandaqi -keyalg RSA -validity 10000

Password is always "t78E68630K"

## Marketing

Odd creatures have sabotaged our electricity cables, leading to a blackout! Without energy, how will we defend ourselves? No longer able to look at screens all day, the humans put out a desperate cry for help.

That's when the *Windup Wizards* arrived. They don't need electricity. They don't need power. You just wind them up, building and building energy, until you decide to *release* it.

Hopefully, they can turn the tide against this powerful invasion of *Energy Exterminators*.

### How to play?

You are a magical gust of wind. Each move, you can fly in any direction, until something stops you.

Flying past the knob on a Warrior will rotate it that way, building their energy.

Pressing a button will unwind all warriors and make them execute their actions! (They execute the action exactly as many times as they were wound up.)

### But how do I win?

Whenever a Warrior meets an Exterminator, they remove it. Remove all to win.

## Entities

### Wizards

They repeat their action as many times as they were wound up. If they are *support*, they do their action on all *adjacent* entities (and not itself).

-   **X Move:** moves \# spaces in the direction it's facing

-   **X Attractor:** attracts the first thing it sees, \# times. (Variant: **X Repulsor**.)

-   **X Jump:** same as move, but ignores anything in its path, and just lands on the target square => Also doesn't activate if number is 1, as that would be useless.

-   **X (Test) Passthrough:**

-   **X (Test) Battery:** when entering it, the number on it is transferred to you.

    -   In support, its number is transferred to all *adjacent entities*.

-   **X Destruct:** if 0, does nothing.

    -   If positively wound, destroys itself

    -   If negatively wound, destroys the player (if on the same square)

-   **X (Test) Converter:** converts entities to the other team (good\<=>bad)

-   **X (Test) Rotate:** rotates \# quarter turns

```{=html}
<!-- -->
```
-   ~~(**GameTurn:** when entered, you get \# extra turns => bit experimental)~~

### Special Properties

These can be toggled on/off on *any* wizard, regardless of type:

-   **X Auto:** doesn't need activation; just executes itself once your turn ends (used as *tutorial*)

-   **X Support:** converts it to a support type

-   **X Team:** either good or bad. (Remember: to win, no bad entities must be left.)

-   **X Rot:** starting rotation (0-\>4).

The "immediate" property doesn't work this way: it depends on specific types, and doesn't work elsewhere.

### Other mechanics

**#1:** There are loose **knobs**. You can pick them up. The first time you enter something, that knob will be added *at the side you entered*.

**#2: Stacking.** From a certain point, different entities can enter the same cell, and they'll just sit on top of each other.

## Menu

Place a bunch of these things in a grid, with one knob at the side. Each is related to a single level. We still control the gust of wind and winding up something starts the level.

On this grid (at all intersection points) are special "pause cells" that pause the player movement there. (Otherwise we cannot control how far it moves.)

Unlock everything at the start, but keep track of what we've already solved. (Don't want people getting stuck on level 2 and never seeing the rest of the game.

# Tutorial/Campaign

**Menu:**

-   Teaches the movement (and that you're a gust of wind)

-   And flying past a knob to wind up something

(At the start, everything *auto-activates*, the player is *not dragged with entities*, and there are *holes* to remove bunnies instead.)

## First Steps

**Level 1-2:**

-   Push bunnies into holes

-   Fly past knobs to activate entities

**Level 3-4:**

-   Flying counterclockwise activates entities in reverse

**Level 5-6:**

-   From now on, winding up just increases the number, making it ready.

-   Fly *into* something to actually activate it.

**Level 7-10:**

-   When activating something, it does its action *as many times as it was wound up*

## Lots of Bunnies

**Level 1-4:**

-   For the first time, we get *multiple entities*

**Level 5-8:**

-   When activating something, it drags the player with it

**Level 9-10:**

-   Some more complicated ones

## Wizards Arrive

**Level 1-X:**

-   When wizards meet bunnies, they remove them

-   (The "holes" are gone.)

Do one with simple removal, one where bunny itself must be moved as well, then just scale the level size. (Don't go on too long, though.)

## Attractive Wizards

**Level 1-5:** The attractor wizard attracts the first thing it sees.

**Level 6-10**: The repel wizard repels the first thing it sees

## Knobcatchers

**Level 1-X:** loose knobs appear.

-   Fly over them to grab them

-   When you enter something, and you have a knob, it adds it to the side you entered

## Bunnyhops

**Level 1-X:**

-   The jump wizard will *jump* as many spaces as wound-up.

-   If its value is 1 or 0, it won't activate at all.

## Supporting cast

**Level 1-X:** adds a new type that all wizards can be: *support*. They execute their action on all neighbors (non-diagonally), instead of themselves.

## Carousel for Carrots

**Level 1-X:** introduces the *rotator* (always support), which rotates something 90 degrees.

## Sorcerer Stacks

**Level 1-X:** from now on, stacking different entities *is* allowed. (So you can enter another cell that already has something of the same type. You just jump on top of them.)

## Loose Loyalties

**Level 1-X:** when activated, converts itself to the other team (as many times as it was wound up).

## Bombing Bunnies

**Level 1-X:**

-   The destruct wizard does nothing when number is 0.

-   If positively wound, it destroys itself

-   If negatively wound, it destroys the player.

## Seethrough Acts

**Level 1-X:**

-   The ghost wizard stops you when number is 0.

-   When negatively wound, you can't enter its square

-   When positively wound, you can move through without stopping.

## Battery Bunnies

**Level 1-X:**

-   When activated its number is transferred to you ( = "all entities on the same square")

-   The next time you enter something, your number is added to *them*.

**Level 5-9:**

-   In support, batteries transfer their number to their neighbors.

## Wildest Wizards

**Level 1-X:**

-   Encounter-stopping is disabled (so stuff just continues after an interaction)

-   Everything enabled, everything can be a support, big levels, go crazy.

# To Do

## Publish

-   Update a few screenshots + trailer

-   Update pages to reflect new content

# Future To-Do

## Bugs

**BUG:** When jumping, the value isn't reduced until the jump is complete. This means that, if we land on something and stacking is enabled, the stack uses our *original number*.

> I don't know if this bug is already present in earlier levels (check the stacking level), so don't know if I can change things now.
>
> Would be a bug with the "immediate" action types
>
> **Here's what happens: when we stack, we add the number *before* reducing it because of moving.** (This is constant and never surprised me until now, so it's probably intuitive and stuff.)
>
> The "MYGy" (loose loyalties) level is *correct* in the game. But the simulation thought that the double jump, somehow, left the converter with **1**.
>
> How could that happen? 1) It only added 1 and didn't activate (unlikely). **2) It activated, but only *once*, stopping when it had one left.** 3) It somehow added a knob at the top, which wound up the thing when we move on the top line (unlikely)

**Needs more data.** (If no "bad" levels come in anymore, just ignore.)

**BUG:** First turns (5) the player gets stuck in an infinite loop when using a hint (I think):

-   <https://www.youtube.com/watch?v=OeGPOud-MRY>

-   He starts each level with this short of "shuffle/circle around the board one full circle"??

## Visuals

-   The grid is a bit *too* chunky perhaps.

-   Make "support wizards" more obvious?

-   Less monotone levels => extra 3D models around/on level, different versions of tiles and bunnies/hats

-   Change the swishy font to something more legible and/or bigger, where necessary.

# To-dos done

**~~Level doubts:~~**

-   ~~The third level in "Attractive Wizards" is perhaps too big of a jump (coming from the easy one before it)~~

-   ~~The last level of "Wizards Arrive" is perhaps too easy.~~

**Menus:**

-   ~~Should completed levels also change their hue towards green? => no easy way to do it~~

**UI:**

-   ~~Add little "wind up + move outward" animations for UI buttons? => don't see the point now~~

**Itch/gamejam feedback**

-   ~~**Is this fixed?** When a move is planned, but that move is *invalid*, it just enters this neverending loop (with an annoying sound effect as well)~~

-   ~~**Is this fixed?** Forbid diagonal vectors in all cases~~

-   ~~On game over, allow choosing actions using the *arrow keys* as well. Because, well, the sprites are already displayed correctly for that.~~

    -   ~~And fix the annoying "reminder show/don't show issue"~~

-   ~~The extra buttons (Q+E for camera, WASD) don't work according to some? => specify they need to be *held*~~

-   ~~Pressing exit somehow activates fullscreen? => can't change this, will probably remove the web build anyway~~

-   ~~Give text a **border** and/or **drop-shadow** and make it more "sans-serif"~~

-   ~~Tutorials were being missed => make them pop up more, flash once in a while~~

**TO DO: Integrate the wind-up mechanic *and* theme in more and better ways**.

-   Something to turn on/off *lights*? Something with solar power?

-   Something with a windmill?

-   Maybe the exterminators actually *do* something, other than exist. They block lights, cut off electricity lines, etc. => since exterminators just became other entities, this is not relevant anymore)

**GREAT RESOURCE ON GODOT LIGHTING AND SHADOWS:** <https://www.reddit.com/r/godot/comments/p9hl5y/directional_light_shadows_are_awful_no_matter/>

-   Discusses a default for small-scale, "simple/low-poly" scenes

-   Discusses how to make it work for larger scenes

-   Good examples and points.

**THIS IS HOW YOU'D ADD 3D TEXT (editable, non-premade model) IN GODOT:** <https://godotengine.org/qa/10913/text-object-in-3d-space>
