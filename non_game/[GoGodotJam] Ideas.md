# GoGodot Jam (2)

## Data

**Theme: "Energy Source"**

**Deadline:** November 30^th^

Submit game to itch.io.

Obviously make it with Godot.

## Voting

1.  **Technical** -- Does the game work? Does the game show off the engine? Does it do anything particularly impressive? Is it feature rich?

2.  **Artistic** -- Is it pretty? Are the sound and visuals effective and fitting? Is the style coherent to the gameplay? Are the text boxes legible?

3.  **Design** -- Does the game teach you how to play it? Do the mechanics make sense?

4.  **Gameplay** -- Is it fun? Does the difficulty scale? Are there accessibility options? Have I played the same game before or is it innovative?

5.  **Theme** -- Does the game fit the theme? Is it surface level or is the theme at the core of the game?

## Brainstorm

**Puns:**

-   Energy Swords

-   Anarchy Source

-   Energy Slowers

-   Energy Showers

-   Cannery Source

**Literal:**

-   Electricity

    -   Circuits, connecting stuff to each other, giving energy to it

-   Grab energy/use (limited) energy

-   Something with physics and actual energy formulas

**Figurative:**

-   Mental energy (positive people/influences in your life, negative)

-   Something like "energy in the nature" or "balance of the universe"

**Negatively**

-   Destroy the energy source of your enemies

-   *Stop* people from using energy. (Climate Change-direction.)

-   *Humans/the player* is the energy source in some twisted world. (We're the ones being hunted and eaten.)

**Meta:**

-   Energy consumed by playing video games (lower it?)

-   How bad playing video games is for your health (actually), sitting still and all. How much energy do you expel?

**Existing ideas I can repurpose:**

-   **Spatterfight** => the different surfaces/liquids are your *energy*. Playing silly games like this is how children regenerate energy. Think of some extra twists to reinforce this idea.

-   **Olympigs** => you have a certain amount of *energy* at the start of the race. This can be refilled with those homes/powerups along the way. Add some extra twists to further reinforce this idea.

    -   Maybe one pig carries the "Olympic Torch", getting extra energy each second.

-   **Wheel of Inputs** => in a sense, your *inputs* are also the *energy* you're able to put into a game. If I can connect this idea of "shared inputs, on a rotating display" with "energy source", it could work.

    -   We can always improve this by saying you're *stealing* energy or *collecting* energy from the level.

    -   Which, in this case, would just lead to *more actions to take*.

    -   (Or ... fewer actions to take? Because a wheel filled with actions is actually not beneficiary, as it takes loads of scrolling to get past everything?)

    -   (Maybe, each time you get enough energy, you have a choice: either **remove** an input or **add** a new one.)

# Dreambringers

Already used. So is "Dreamaway", "Dreamdoves", Alternatives:

-   Dreamshufflers

-   Dreamdroppers

## General

**Local multiplayer, Cooperative**

**You are part of a team tasked with delivering "energy" to everyone who sleeps.** (That's how you "regenerate energy" in the night :p)

Should be a cute theme. Maybe this "energy" is even more specific: the dreams you get are about *love* or *friendship* or *future/awards/prizes*. Lots of lighting effects and a cool night theme.

The map shows a world divided into timezones. (So the night moves from left to right, then repeats.)

## Goal

Whenever you forget to revitalize someone, they will not wake up the next morning. The game ends when nobody is left. Try to get the highest score possible.

## Input

Every player is a **dreambringer**. You can

-   Move around

-   Collect dreams + drop them

**QUESTION:**

-   Is this a top-down game?

-   Is it a ¾ view game? (With houses popping up, and you literally *drop* the dreams on top of them?) => in this case, a 3D world might be better?

-   Is it a complete side-view game? (More like a platformer?

**IDEA:** People *emit* energy/dreams during the day, by doing stuff. A musician emits notes that you can collect. Somebody talking also *gives* energy. Somebody kissing emits *love* energy.

> But the more energy you *take* from someone during the day (or the more they emit in general), they more they'll require at night.
>
> (So by being observant, you can prepare for someone needing lots/little.)

**IDEA:** But ... sometimes no energy is emitted, or *negative* energy.

> And maybe they also need it during the day on "big moments". (Exercising, working, confessing their love, speaking in front of a crowd, etc.)

## Theme

Strong. The idea of "grabbing the energy people emit" and "giving it to people who want it (to recharge during the night)" is quite strong and intuitive.

## Feasibility

We'd need:

-   A player that can move/fly, drop and collect stuff

-   Random map generation

-   Entities that can do stuff on their own (go to sleep, wake up, emit dreams during the day)

    -   Quite intricate state manager

    -   Quite intricate models and animations

-   A list of all possible dreams, entities select from them.

    -   Emit dreams

    -   Request dreams => when received, recharge, and give player points

-   If not enough energy, don't wake up. If no active people, game's over.

-   A list of unique dreams and unique people, possibly with special powerup powers.

**Feasible?** Yes. Although the models and animations might be a bit sketchy.

# Party game

You need to attack the other players. But to do so, you need to regenerate your power:

-   Run over a "hamster wheel"

-   Stand in the (sun)light for solar energy

-   Move through the air for wind energy

-   Plug yourself into an actual power outlet

To complete the picture, arenas could be themed:

-   Fighting on a windmill

-   Fighting in an Oil pump

And maybe arenas *in general* have some energy/electricity level, which is used for some stuff.

# Einstein

Finestein? Winestein?

## General

**A physics platformer/puzzle game about the "Conservation of Energy"**

-   Would need to invent a few clever (simple, relatively well-known) rules for how things work.

-   But the general idea would be: "everything is an energy source => but it can be positive or negative, based on how you use it"

Use Albert Einstein or something

-   Something with inverting the laws of physics?

-   Falling expends energy. Kicking something upwards brings it back.

-   Putting something in motion takes energy. Stopping something returns the energy.

-   "Law of Conservation of Energy"

## Goal

Drop an apple on Newton's head. (Or, more generally, hit Newton with an apple.)

## Input

You can move around. With one button you can alter *potential energy* in an object (can be yourself), with another you can alter *kinetic energy*.

Something like *jumping* is done this way as well => add kinetic energy to yourself. You can stop your fall by removing your potential energy. Stuff like that.

## Energy (Physics explanation)

You need **energy** to do any **work.**

There are two types: kinetic and potential. These can be *converted* into one another.

**Potential Energy**: energy stored by virtue of an object's position or parts/arrangement. It's *not* affected by surroundings. It can *not* be transferred, but simply depends on the object's mass/distance.

**Kinetic Energy:** energy of an object in motion. Relative to its surroundings (placing something higher, gives it more kinetic energy). Can be transferred by hitting other objects.

**Kinetic Energy (movement of any kind)**

-   Electrical Energy (movement of electrical charges; the actual atoms)

-   Radiant Energy (electromagnetic energy travelling in waves)

-   Thermal Energy (internal energy in substances, caused by the vibrations of molecules)

-   Motion Energy (movement of objects from one place to another)

-   Sound (movement of energy *through* substances in the form of longitudinal waves)

**Potential Energy (stored energy)**

-   Chemical Energy (stored in bonds of atoms and molecules; it's what holds them together)

-   Stored Mechanical Energy (stored in objects by application of force; e.g. compressed string)

-   Nuclear Energy (the energy that holds the nucleus of an atom together)

-   Gravitational Energy (the energy of position or place)

URL: Good Explainer => <https://justenergy.com/blog/potential-and-kinetic-energy-explained/>

# Cloudcatchers

**Explore the idea of wind energy more**

Cool art style, about wind and sailing: <https://store.steampowered.com/app/417200/Make_Sail/>

A platformer in a world where all energy has faded and the sun has gone out.

The only thing blowing is the wind.

Use it to move around, use it to generate energy, until you can finally turn on the single light inside the level.

**Could be combined with the "Einstein" idea** => using the wind to move also takes away energy somewhere else.

# Gymportant

The Endless Fitness. Neverending Fitness. Gympossible Cycle?

You operate a fitness class/gym.

But ... the power required to get the gym going *is generated by the people themselves* (by running on stuff, pulling stuff, etc.)

By exercising, you deplete your *physical energy*, but recharge your *mental energy*.

Over time, your mental energy automatically drains, and your physical energy automatically increases.

(This is similar to that idea of using "running wheels" from Hamsters to power everything.)

**How would it actually play?**

## General Idea

You have a gym, divided into a grid. You can place an entrance/exit however you want (or this is randomly generated).

People will enter and walk around randomly. Once they are tired, they'll try to leave.

You can place *fitness machines* ( = 1 cell grid blocks) in their way! They are forced to use them to get through. And doing so generates energy for you.

But ... only if they are powered. Any non-powered machine is useless and does nothing.

So it's your job to keep your total energy level high enough. Because if it dips too low, you can't place new machines and random ones will shut off. And if it's below some threshold, you lose entirely.

## Goal

Keep your business alive as long as possible.

## Input

Select blocks from an inventory and then place them. (Or do it "Islander" style, where you get a selection of them each time, and you pick the one you want?)

## Theme

Very good. The whole thing is about maintaining high electricity levels. The "people use machines to generate electricity" + "machines need electricity to work" is a never-ending thematical feedback loop.

## Feasibility

I'd need to:

-   Create a random room (with exit/entrance and grid)

-   Allow placing/removing stuff at locations

-   Create a list of possible machines

-   Create a general Energy counter + something that takes/adds energy per machine

-   Create people + walking animations + semi-intelligent walking behavior

**Somewhat feasible, not great.** This can work in 2D, but it's certainly not desirable. (Hard to do animations and machines in a good perspective.) To make people walk in 3D, and animated machines in 3D, is also quite the challenge.

# Badminton

**Great name:** ***Racket Peeps*** or ***Racket Men*** or something like that. Because you're literally playing characters that *are* the racket.

Could be a fun game, if we just make the racket completely realistic.

## Movement Scheme #1

-   When using your joystick, you move your *racket*.

-   You can't move it further than some max distance.

-   When pressing a button, you either *snap to your racket* or the *racket snaps to you*

-   *Alternatively:* you can only position the racket, *hitting* goes via rotating your whole character.

## Movement Scheme #2 (seems better)

The players **are** the rackets. They simply extrude from the top of their head. By rotating, jumping, running, diving you can hit the shuttle.

To make this all a bit more controlled, I probably need to add *walls*, teamplay (everyone on a team may hit it max 1 time), maybe a bouncier shuttle.

## Input

-   **Joystick:** rotate (with Y-axis fixed)

-   **Button:** Jump

    -   When in the air, pressing it again will do a **dive**. (In the direction you're pointing.)

    -   If no direction, it does a **salto**. (Which is basically the same as a swing.)

While diving/jumping/etc. you can still use the joystick, of course, to re-orient yourself.

Instead of *pressing*, we might also switch to *holding*. As long as you hold it, you are rotating/diving. This would allow you to stop holding it/slow down to get slower shots and dropshots.

Some possible rotations are **missing** now. (Such as a sideways racket swing, like Tennis.) See if we can somehow incorporate them, maybe behind a different button, or just a temporary powerup.

## Mechanics

If players can move and do whatever they want, it might get a bit "stale" or "repetitive" soon. In real life, players have *stamina* and stuff. So try to copy that

-   **Stamina:** the more you run/jump/do weird stuff, the more stamina it costs. If it goes below some value, you start walking more slowly, and actions become more *random*. (As in, not as precise as your inputs.)

-   **Player Roles:** different characters might have different *stats*. Some are a bit faster, some jump a bit higher, etc.

-   **Different Rackets:** same idea => some rackets are bigger, some hit harder, some have different **shapes**, some can be extended (like they're attached to you with an elastic), some have more distance to the player (or fewer)

## Variation/Content

-   Different arenas

-   Different shuttle types

-   Powerups => although powerups to grab might be a bit boring, it *does* mess with player's positioning

    -   These might also change what your buttons do.

-   Different modes/rulesets

## Physics

### Shuttle

-   Make it a RigidBody that's extremely lightweight, but with huge drag.

-   Just *slowly* rotate the shuttlecock to match the velocity it's pointing.

-   It reacts way more strongly to the racket bodies (than players, or anything else), more bouncy and stuff.

-   (Just use custom collision code for this, getting contacts. Will need that anyway, for when I implement different shuttle types and stuff.)

### Net

Use a *soft body*, which is just a plane that's subdivided a lot.

### Players

Lala

## Trailer

"Badminton is easy ... " intro overview shot, somebody serves

"You just walk around ... " more walking

"Hit the shuttle ... " someone jumps to hit the shuttle

"And -- WHAT WAS THAT?!" someone does the dive/salto to smash a shot.

From that moment on, it's just flashes of the game, getting more and more ridiculous.

## Other modes

Well, those could just be other sports:

-   **Badminton:** base mode.

-   **Table Tennis**: A table separates you. It's a ball and it has curve. It must hit the table.

-   **Volleyball**: The net is higher, you play with a big ball, there's this huge hand/glove on top of your head

-   **Soccer/Hockey**: Your racket is mounted *sideways*, so rotating will swipe it against the ball. There are goals in which to score.

-   **Speedminton:** no net, players stand in squares (delineated by lines on the ground) with quite some distance between, underhand serve => shuttle is much faster and air-resistant

-   **Dynamictennis:** ??

-   **Padel tennis:** tennis in a cage. Ball must first hit the ground when coming to your side, but afterwards you may use the walls any way you like.

-   **Squash =>** **Racquetball** (a bit more freedom)

-   **Lacrosse => Hurling** (more aggressive)

-   **Spikeball/Roundnet:** Round flat net in the center, mostly follow the original rules

-   **Pickleball:** badminton court, low net, "no volley zone" around net, hard paddles and ball with holes, serve = stand behind baseline, diagonal into other zone, underhand (below waist)

    -   "No volley zone" = you can't return the ball directly, must bounce before you may hit it there

    -   "Two bounce rule" = the ball must bounce once on other side, then once on server's side, *before* you're allowed to start volleying

    -   "Serve points only" = you only get a point if you win a rally *where you served*. If you win a no-serve, you get to serve next.

    -   Also some special serve rules (about which side and such), look it up when needed

-   **Cornhole:** maybe not for this game, but still fun in general

-   Ultimate Frisbee: ??

The important thing is that as much of the **inputs, movement, mechanics, etc.** stays identical between modes. So players don't need to learn anything new, I don't need to code anything new, etcetera.

There are way more (interesting, quite new) racket sports than I thought: <https://nl.wikipedia.org/wiki/Lijst_van_racketsporten>
