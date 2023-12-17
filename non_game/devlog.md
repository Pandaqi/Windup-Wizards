\[Devlog\] Windup Wizards
=========================

Alright, so, the GoGodot Jam 2 happened. I decided to participate. This
was decided well in advance, and I scheduled my other projects around
it.

But, as is the case with game jams, I couldn't start doing anything
until the jam actually started and the theme was revealed.

Because of timezone differences, and a little disappointment with the
theme (which I'll explain soon), this meant I had basically **10 days**
to make a game.

In this short devlog, I'll talk about creating *Windup Wizards* from
start to finish.

Theme
-----

The theme for the jam was **Energy Source**. It's an okay theme, and I
can see why they'd pick it.

At the same time, it didn't help me at all. There are *many* cliché
interpretations in relation with games.

When the theme was announced, they said something like: "Don't go the
obvious route of making energy sources that the player can collect!
Instead, for example, you could look at *mental energy* -- things that
make you happy or not."

Yeah ... but that's also obvious. Game developers are more creative than
that. Almost *everything* that came to mind with this theme was an
obvious, overused, video game trope that 100 others will also have come
up with.

I wanted to create an action game, as puzzle and platformer puzzle games
are overdone at game jams. But combining that with the theme ... it just
didn't work. I couldn't find anything.

The same was true for other genres I hastily explored (such as a sports
game).

There was an idea for "delivering dreams to give people energy for the
next day", which was a *great* application of the theme (in my eyes),
but not feasible to create in such a short timespan. It would have to be
3D to work well, with which I have way fewer experience than 2D.

There was an idea for a platformer game where you could manipulate
everything following the laws of physics. (Moving things have kinetic
energy, static things have potential energy, etcetera.) But the further
I dove into the topic, the more the game would become a physics lesson
nobody would understand but Einstein himself.

There were ideas for other games, but those were, frankly, only
*vaguely* related to "energy". Because, I mean, energy is everywhere.
Any action costs energy. Energy is needed to do any "work" (both
practically and theoretically). So yeah, *any game idea* could be
related to this theme.

That's where my disappointment came from: it's both too specific and
cliché for games, and too broad to be any theme at all. But hey, it is
what it is, let's try to make it work.

In the end, after talking with some family members about it, I settled
on an idea that was

-   Very thematic

-   Feasible, as the art style would be simple, and much of the logic
    would be something I'd already coded before

-   Not likely to be done by many people

-   Able to have a life beyond the jam. (I don't like creating games
    that will basically only be played during the week after the jam,
    and then forgotten and buried.)

Windup Wizards
--------------

This was the idea: **a puzzle game where everything in the level must be
*wound up*** (like those old toys)**, then *released* to do their
action**.

As for theme, I think it more than fitting enough:

-   Why must you wind up everything? Because there's no electricity, no
    energy source.

-   In a sense, those toys are batteries/energy sources themselves

-   And to finish the thematic tie-ins, I made the story revolve around
    some creatures nibbling on our power cables, and you have to remove
    them.

As for the rest:

-   I couldn't find anything like this that's been done before.

-   I've made big puzzle games in the past. Learning from that, it
    shouldn't be hard to create most of the puzzle *game*.

-   A few days prior to the jam, I was experimenting with learning a new
    language (Rust) for doing simulations. This seemed like a perfect
    opportunity to use it to *simulate* ( = randomly generate) puzzles
    for this game.

Note that I won't just randomly generate 100 puzzles, stick 'em in the
game, and call it done.

I've experimented with this for months last year, and learned that I
should use these as an *inspiration* or *starting point*. I still have
to manually play and select the best puzzles, and perhaps alter them if
I see improvements.

Why wizards?
------------

The process went as follows:

-   Let's make a quick sketch for this game

-   Hmm. What creatures nibble on power cables? Bunnies!

-   Let's call the game Windup Warriors. Oh no, that already exists.

-   Hmm. I don't want this game to actually kill bunnies, nobody likes
    that. Instead, they should be *shoved off the board?*

-   No, too complicated. Instead they should just *disappear?* Yes! If
    the toys are magicians/wizards, they can just put the bunny back
    into their hat, like a trick.

That's how the general theme and name came to be.

The main mechanic
-----------------

Then I had to answer the question: **how will you wind up those toys?**
Well, by rotating the knob on their back.

But how do you do that?

-   Idea 1: when you bump into them. Not great, as "bumping into
    something" is an action that's hard to see or reason through.

-   Idea 2: an actual button to press when near a toy. Not great, as it
    requires that extra button. Does that count as a move? Or not? What
    if multiple knobs are nearby? Meh.

-   Idea 3: by walking/brushing past it. Yeah, seems intuitive. But this
    means you need to do a lot of *walking* to get around toys and brush
    past their knob.

-   Idea 4: you are a gust of wind that will *fly as far as it can* on
    every move. Flying past knobs rotates them. That's a winner!

Because you move until something stops you, you can travel greater
distances and puzzles are less "boring" or "static".

However, still *something* needs to stop you (besides the level bounds),
so I added the rule:

-   When you encounter a wizard, you stop on the same cell.

-   Then you **activate** them.

Activating means that it *unwinds* itself and executes its action! If
you've rotated the knob 3 times, it will activate its action 3 times.
(So, rotating the knob more times, will store more "energy" in them.
Theme, theme!)

(Again, I could've put "activation" on an extra button. But I've learned
over the years that *simplifying controls is amazing*. You should do it,
and you *can* always do it. If you think "we need an extra button for
this special action", think again if you really need this action, or if
you can't streamline it more with the existing controls.)

So this idea of "stop on wizards, active them" solves two problems with
one stone :p

At first, I executed this "rotate knob" code any time you entered a
cell. But this could easily be exploited for "boring puzzles", as you
could just *shuffle* in and out of a cell to add more and more energy to
a wizard.

It also didn't make much sense. It's more logical if a knob is turned by
moving *through* the cell, so that's what it became: anytime the wind
moves to the next square, *that's* when it checks the previous square
for knob activations.

The objective
-------------

Which means one piece of the puzzle remains: how do you win? Well, by
removing all the "bad" entities. When a good entity enters the cell of a
bad entity, they remove it.

At first, I split those into two distinct groups: wizards and the bad
creatures to remove.

But I soon realized this was making it more complicated, with 0 benefit.
It's way easier to make **everything a wizard** (both when coding and
playing), but some are **good** and others are **bad**.

This means that I could also, for example, wind up a bad wizard, then
activate it to send it straight into its death :p

It streamlines everything, whilst adding way more options to the
puzzles.

In summary:

-   Win by removing all bad wizards

-   Lose by being removed yourself (or running out of turns, obviously)

Solving some deficits
---------------------

### Moving is too important

By sketching the first few puzzles, I quickly saw a problem. I added a
"Rotator" wizard, which, when activated, rotates itself.

But ... there's literally no point. Rotation doesn't matter, unless you
can move.

-   Idea 1: give wizards multiple actions. Nope, way too complicated,
    can't visually make that clear to the player.

-   Idea 2: allow wizards to change their action. Could work, but would
    require extra wizards and extra rules *just to make this working*,
    which is bad.

-   Idea 3: They can't move themselves ... but maybe **others can move
    them**. Winner!

I invented the "Attractor" wizard. When activated, it attracts the first
entity it sees towards itself. This allows moving everything around,
even if they don't have the "Move" action themselves.

### One action at a time is too slow

Because you need to both *wind up* and *activate* entities, puzzles can
be a bit slow. (It takes many turns to get somewhere and do something.)

To solve this, I added **support wizards**. (Again, these started out as
a separate class of entities, but then I changed it so you can toggle
"support = true/false" on *any* wizard.)

They don't execute their action on themselves, but on **all neighbors.**
(Horizontally and vertically. Diagonally was too much.)

Another solution was **auto wizards**. At the end of a player's move,
the game checks for any auto wizards which have energy ( = they've been
wound up at least once). Those automatically activate. *These are also
great for the first few levels, to simplify the explanation*.

### Static knobs are boring

So far, wizards just start with one (or multiple) knobs in them, and it
never changes.

This means my simulation will create *many* puzzles that are unsolvable
( = not the right knobs) or just stupid ( = wizards have way more knobs
than needed)

It also really constricts your options, making puzzles easier or more
"samey".

Then I realized: I can add and remove knobs at will! There's nothing
stopping me!

The plan is to add knobs just *lying around* in a level. When you move
over them, you pick them up. When you enter a wizard, and you have a
knob, it's added to them (at the side you entered).

Not sure if I have time for this within the jam, but it is a cool idea.

### Something that seems more intuitive

When you activate a move wizard (for example), it will move away from
the player. The player is just left on the cell where the wizard used to
be, lonely and stranded.

Although this can be *fine* ... it felt more intuitive that the player
*moved **with** the wizard they activated*. In a sense, the player is
the one controlling or activating that entity, like they're sitting
behind the steering wheel. It just feels logical to have them move
along.

This did make matters more complicated in my code, especially the
simulation (as I need to keep an eye out for *performance/speed*), but I
just had to add it.

Also because it, again, speeds up the game: you can use other wizards to
move around faster now.

(A puzzle with more than 10 "moves" quickly becomes overwhelming and not
"fun" anymore. That's why I'm so concerned with making the player quick
to move around and take actions. Think about it: you open a puzzle, and
it says "22 moves to complete", do you feel great about that?)

First steps
-----------

Within half a day, the puzzle *game* was up and running. The other half
of that day was spent setting up the simulation, creating a basic
framework onto which to build the actual game logic.

The next day, I fixed some issues with the puzzle game and wrote code to
load a puzzle from a .json file.

Then I went to the simulation to actually *make it work* and export its
results to a .json file.

I wasted an hour or two thinking something was wrong with my simulation,
when in actuality something was wrong with my *game*. The simulation was
100% correct, the game just didn't work as it should.

Here's the problem: moves should take time. You don't want to *snap* the
player to the next cell instantly. It should be animated/tweened. So,
you need to *wait until all previous animations are done* before
starting the next one.

In earlier puzzle games, this was *hell* to program, and ended up using
tons of code, checks, variables, callbacks, etcetera.

This time, I want to use *coroutines* and the *yield()* function (in
Godot) to simply pause and resume functionality. But I'm not that
familiar with it yet, so I kept making mistakes, not knowing how
yielding actually worked.

(I tried to do it all via signals, which was a mess. Then I learned that
the yield function itself *has a "completed" signal* which fires
whenever all is done, which was *exactly what I needed*. So a bit of
rewriting later, it now neatly waits until everything is animated before
continuing. And with rewriting, I mean "putting yield() around almost
everything" and "making every action/command create a tween of some
sort, even if it's a meaningless one")

First steps, again
------------------

I like to create tutorial images/text/placeholders *very early* in
development of a project.

This shows me how simple the idea *actually* is to teach players. How
many steps we need, how much text, whether simple icons are enough to
convey certain concepts, etcetera.

Doing this showed me that the idea for this puzzle *wasn't as simple as
I thought*. To get a "working puzzle", I'd need to teach these things to
players on the first level:

-   Input? Arrow keys to move, you move as far as you can.

-   Objective? Remove all bad wizards.

-   When brushing past a knob, you rotate it, winding up that entity.

-   When entering an entity, you unleash this energy, and it repeats its
    action as many times as it was wound up.

-   Good wizards remove bad wizards when they encounter them.

That's quite a lot, eh? :p Way too much at once, which forced me to
rethink it a bit and strip some mechanics for the first 10 levels or so.

The main problem was: I needed good *and* bad wizards for the game to
work (as the good ones remove the bad ones), and you need some control
over them ... which automatically means at least 3 or 4 things to
explain at the start.

So, what if we just **remove** those good wizards for now? This became
the plan.

In the **menu** ...

-   Teach players how to move. (As they'll use that to navigate the menu
    as well.)

-   Introduce the concept of "winding up things", as they need to wind
    up a block to load that level.

In the **first level**

-   **Teach the objective**

-   Add only **bad wizards and "holes"**.

-   **Teach** "When a wizard falls into a hole, they are removed"

-   Wizards auto-execute.

From that point, slowly introduce the "actual" mechanics of the game.
Remove the holes, replace them with the good wizards. Don't
auto-activate entities, only when you enter them. Etcetera.

In total, I needed 9 tutorial images for all of this, which would be
spread across 10-20 levels.

If this were a real project, I'd go back to the drawing board and
rethink the core mechanic. A puzzle game's core should be *simpler* than
this, explainable in the first level, and the rest of the game should
build on it. But because it's a game jam, I have no time to dawdle and
must make decisions now. So I decided to continue with the current
logic/rules and teach them in this spread-out way.

Finally, we're getting somewhere
--------------------------------

After many stupid mistakes in my code, we have a working simulation, and
a working game to play the puzzles it generates.

(For example, I accidentally wrote code that only checked for knobs to
turn *at the end of player movement*, not during. I don't know what was
going on in my head when I wrote it. It wasn't even late at night or
anything. Removing that one check ("if stopped") was the end of 1.5 hour
of scratching my head, trying to find the weirdest of bugs.)

### 3D it is

When sketching the game idea, and some possible puzzles, I also become
certain this had to be **3D**. Otherwise, it was just too hard to see
knobs that were at the back, or holes behind entities, or when your gust
of wind was behind/inside something.

Additionally, it would make many animations easier (such as the rotating
knobs), as I wouldn't have to draw perfect perspective for many frames.

Aaaand because I've already done *loads* of 2D games this year and
wanted to brush up my 3D skills. (Which are still not great, so the
models for this game will be kept really simple: magician hats for the
good wizards, low-poly bunnies for the bad ones.)

**Remark:** it did remind me that *rotations in 3D are stupid*. Even
after all this time, I still think they will just work one way ... and
then they work a different way.

Nope, still more mistakes
-------------------------

In my undo system, I added the command to the list AFTER executing it.

But ... commands can execute other commands, so doing this would lead to
stuff being undone in the wrong order. A miracle how it never failed
before until now :p

I also remember why I did it: in Rust, variables can only have one
owner, and if I added the variable to the list *before* executing ... it
would crash, as now that list owned the command object and I couldn't
execute it anymore afterward.

Obvious solution? Clone the command to get an independent copy, save
that in the list.

But ... because commands are *dynamic* (they can do anything and hold
any data, they just need to implement do() and undo() properly), calling
"clone()" on it just crashes the system.

After trying to understand how manual cloning works exactly in Rust (for
the better part of an hour), I realized: this is too complicated for
something so simple, surely I'm just approaching the problem in the
wrong way.

And sure, a few minutes later I realized: I don't need to clone the
object at all.

All I care about is its *position* in the list of commands. This is what
solved all issues:

-   Before executing a command, insert a "Fake Command" into the list,
    and remember the index we put it.

-   Execute the command.

-   Now put the command at that index, replacing the fake one.

Simple, three lines of code, and indeed a way better approach to the
problem.

### Simulated start

Then I simulated the first **two worlds**. (In which you're slowly
taught winding up, removing bunnies, winding up in reverse, etcetera.)

This went ... fine. I had to fix even more stupid mistakes and
inconsistencies. But they were small ones, way easier to see and fix
than the others.

Once we reached more complicated levels, I needed more ways to force the
computer to make "interesting" puzzles. Here are some of the easier
ones:

-   Discard puzzles where less than 80% of the squares are *actually
    used in the solution*

-   Discard puzzles that do not use *all* available entities

-   Discard puzzles with a "shuffle": the player just goes back and
    forth a few times to wind up one specific entity, and that's a major
    part of the solution.

### A rule modification

Then I reached the **third world**, where wizards finally entered. After
a few good puzzles ... I generated one that was *technically correct,
but felt wrong*. In it, a player is dragged by a bunny, moving itself
into a wizard (and thus, well, committing suicide).

The player ends on the same square as the wizard. But because it was
dragged, it does not activate the wizard and the turn ends.

It *feels* inconsistent. It *feels*, as a player, that you should then
activate the wizard on which you end!

After thinking about it for a bit, I decided that this should indeed be
the case. This meant rewriting some core parts of the simulation.

-   Instead of checking for activation *when the player is done with
    their move*

-   I should check for activation *any time the player moves*

By now, the code has become quite complex, so I just hope this holds and
I won't encounter lots of strange bugs after this :p

(For example, a simple move to the right, can now lead to: activating
something, which drags the player to somewhere else, which removes a
bunny, which activates something on the place you landed, etc. I've done
my best to code this system in a clean and robust way from the start ...
but I hadn't foreseen this.)

This will allow *chaining* lots of actions together on certain puzzles,
which fits the game itself and the theme for the jam.

### A remark about coding

Okay, if I'm going to complain about code complexity, I might as well
state the *positive* lessons I've learned from this project.

More and more I learn about the power of thinking in terms of
**"commands and queries"**.

On older projects, I'd write everything in terms of *classes*. A "Point"
class would then have methods like "has\_edge\_to" or "is\_unconnected"
or things like that.

Coding complex puzzle simulations, in the programming language Rust, has
reinforced that this is a *bad idea* and *totally unnecessary*.

Instead, I should write:

-   Small, modular **commands** that can be done (and undone)

-   And use **queries** to get specific information about the game
    state.

For example, a "Move" is simply a command that's executed. Which
executes a list of smaller commands: "PositionChange",
"EncounterEntity", "TurnKnobs", etc.

Each of these are no more than 5-10 lines of code, both doing and
undoing them. By doing *everything* this way, all logic breaks into
digestible pieces, and we get undoing + easy chaining for free.

Lesson \#1: instead of adding functionality on *objects*, add
functionality through *commands that do one specific thing*.

But how do these commands know what to do? Well, instead of handing the
command *the specific entity to move*, I hand them a *unique ID*
(referring to that entity). When it comes time to execute it, it finds
the entity that belongs to it. In general, no data is stored in the
commands themselves -- only what's necessary to read and modify the game
state.

That's what I call a "query". Instead of saving information and methods
in e.g. a Point or Cell class, I create a single "GridHelper" object,
which has loads of methods for *reading information from the grid*. (For
example: "get\_cell\_at", "can\_move\_to", "is\_out\_of\_bounds")

Lesson \#2: by doing everything through *queries into the game state*,
your code becomes way cleaner, more efficient, and easier to reason
about.

That's it for "Pandaqi Programming Parables", let's continue with the
devlog.

The messy middle
----------------

Every project has this. You have a basic foundation ... but still a long
way to go until you have a finished, playable game. It's always hard to
get through that, spend time on the right things, keep working at a
solid pace.

To solve this, I usually just write down *every tiny, concrete thing* I
need to do, in some order. When I wake up the next day, I just do what
the list tells me, and cross off the items one by one.

This means that, in this stage, all sorts of things are
added/removed/changed without a clear order to them:

-   Some more 3D models were added

-   Some more animations/tweens were added

-   A bit of UI was added

-   The new logic rule was implemented, and some new levels generated

-   A basic version of the menu + level selection was made

-   A start was made with the iconography and helpers (for players
    playing the puzzle)

Now imagine doing a list like that *a few days in a row* and just hoping
things will get finished and playable eventually :p The life of an indie
game developer.

### Redoing the first two worlds

The first two worlds, by this point, just weren't great anymore:

-   I'd found several issues in the simulation that prevented it from
    finding better puzzles

-   Those same issues might have made older puzzles possible, which they
    shouldn't have been, which means I'd have to recheck all those
    levels anyway.

-   I'd added more and more rules to "nudge" the simulation towards good
    and fun puzzles.

-   By adding 3D models, I was finally able to get a good look at levels
    and how it feels to play them. This made me realize that:

    -   Lots of knobs on an object *without purpose* is just visual
        noise

    -   Starting bunnies with holes underneath them is a bit silly.

So I regenerated those puzzles and put them in the order I thought was
best. Then I could finally do the *third* world, which is where those
wizards actually appear. (Instead of pushing bunnies into holes, they
are removed by encountering wizards from now on (until the end of the
game).)

At the start, I had made a long list of ideas for the wizards. But
seeing that it took 3 "worlds" to even get to the basic "move wizard"
... I might have to settle for just a few simple types.

(Also, in hindsight it might have been *even easier* to start the game
with "suicide bunnies": when you wind them up, they self-destruct. Then
I wouldn't have to explain the holes at the start. But I don't saw a
good way to make this thematic, and "suicide bunnies" wasn't very nice
either, so I left it.)

### Nope, more troubles

I've never made a puzzle game of this complexity before (behind the
scenes), in such a short time frame, in 3D ... and it shows.

Half my day was spent tracking down numerous bugs, both with the
simulation (for generating puzzles) and the game itself.

For example, in games like these there's a (very important) order to
operations. Player moves, which leads to A, which leads to B, which
activates C, etcetera. This order *must* be preserved.

But ... actions take time. I can't just instantly teleport the player to
their final destination, as it looks bad and is wildly confusing.

Even worse, some actions must be done *simultaneously*. For example,
when you activate a wizard, it will both "do its action" and "undo the
rotation of its knobs" (as it's literally winding down). If you do these
in sequence, the whole concept falls apart.

Hopefully you can see where this is going: I must wait for some things
to end, while other things must *not* wait on other things ... and it
quickly becomes a mess. I have it working now, but with a few pauses
here and there (leading to a minor stuttering on some moves) for safety.

And then the simulation. Because it's all just number crunching, it's
hard to get a visual on what's happening and to diagnose problems. Over
these few days, I've already written almost thousand lines of code just
to *debug* the thing. (Print the board, print specific information about
the board, print the numbers on the entities at a given move, etcetera.)

After *hours* of debugging, I finally discovered there was a *major*
issue with entities *dying*.

You see, originally, entities could only die by moving. They'd move from
A to B, a wizard or hole was at B, which killed them. So, how did I
implement that?

-   When you move from A to B

-   You are removed from cell A

-   And if you die, the function stops here.

-   If not, you are added to cell B.

This worked fine for the earlier levels, but when complexity increased,
this proved a stupid implementation. Why? Because now

-   Things can die without moving. (If a bunny sits still, and a wizard
    moves *to them*, they will die. But they haven't moved -- problems!)

-   It makes the command *conditional*, which you don't want. (It does
    different things based on circumstance, instead of doing one
    specific thing all the time.)

-   I rely on "overwriting" the old entity when something new enters a
    cell. Which, again, works for the simple version of the rules. But
    when you think about it, how could this ever work!? By overwriting
    something, we make it impossible to *undo* that operation! What was
    I thinking?!?!

Eventually, I rewrote the code to do the following:

-   Added a "GridTransfer" command. Whenever something changes cells in
    the grid, this is called and handles it properly. If the entity it
    acts on is dead, it does the original behavior: remove from cell A,
    but never add to cell B.

-   Added a "remove\_from\_grid" option to the Kill command. Whenever an
    entity is killed *outside of movement*, this option is true. It does
    nothing more than find the cell the entity is standing, then remove
    it from that cell. I decided to make this a toggle I need to set
    manually, so that I must be *explicit* about this action and reduce
    the chance of mistakes.

On top of this, there were many minor issues with the way I was tracking
statistics or the order of certain operations. But after "wasting" half
that day, everything works smoothly again. The game can do and undo
everything with nice, properly timed animations. The simulation can
quickly find *correct* puzzles for any configuration.

Let's hope I don't break it again when new stuff is added :p (Then
again, this is to be expected when working under the very tight deadline
of a game jam.)

What have we learned?

-   The "do everything through Commands" system is great ... but only if
    you ensure each command is non-conditional and does exactly one,
    clear, properly coded thing.

-   When working with number-crunching simulations, create loads of
    (visual) debugging tools for yourself, so you can find mistakes
    likes these more quickly.

-   Removing something from a game world *always* leads to stupid bugs
    ... it's a pattern I've seen in every project. Adding data is easy,
    removing it is hard. Especially when doing 10000 moves on a board,
    and undoing them as well, one minor slip-up can throw everything
    askew.

The information problem
-----------------------

When I sketched the first ideas for this game, they were 2D. I saw that,
if I made the wizards flat enough, I had more than enough space on their
head to display both their **type** (move? rotate? attract?) and their
**number** (how many times they were wound up.

With that assumption in the back of my head, I just continued working.

But at this point in the development, with a 3D scene, I had to concede
that this just wouldn't work. There's not enough space on top of
entities to *clearly and unambiguously* communicate both properties.

So I listed some ideas:

-   Give each wizard type their own *model* that also shows what they
    do. Problem? Lack of time. I can only manage this if all wizards
    look kinda similar, but then we don't communicate what they do!

-   Show an icon and number above their head. Problem? This occludes
    things in the puzzle (which are behind the icon). And two icons *per
    entity* is just too much.

-   Okay, only show an icon above their head, show their *number* on the
    body itself. Problem? We're not in perfect top view, nor perfect
    side view, so wherever I put the number (top or side), it won't be
    easy to read. (Additionally, Godot doesn't have native support for
    text in 3D, so it would need a messy workaround anyway.)

-   Do the reverse, then. Number above their head (flat 2D), type shown
    on their body with a 3D model. ("Move" = an extruded arrow, for
    example.) Problem? No clear problem, but also not great.

All of them weren't great.

Then I thought: **what if we remove the need to show the number at
all?**

-   If something can't be activated (number = 0), it's a bit greyed-out,
    or lacks a certain effect (glow, particles, whatever).

-   If something is activated in reverse, its model and icon simply
    flip.

-   If something has a value \> 1, we just *stack the model on top if
    itself*. (So a bunny with a number 3 ... is just 3 bunnies on top of
    each other.)

This is great for a number of reasons:

-   Removes the need for ugly/occluding icons or UI overlaying the 3D
    world

-   Actually reversing the model is much more friendly to players than
    showing the "-1" number

-   Seeing 2 hats stacked is much more intuitive than reading a number

-   Stacking wizard hats on top of each other seems fitting and fun.

I'll probably have to stack bunnies differently than hats, otherwise it
looks weird. But I think this is the best way to go:

-   3D model to show what a wizard *does*

-   Stacking stuff to show how much they are powered up

This is going to take *quite* some work to implement, but it's
essential, so let's do that first before continuing.

\<TO DO: Image here\>

Where are we now?
-----------------

Here's an image to give an idea about the current state of the game:

\<TO DO: Image here =\> grab one from my Twitter\>

Not completely polished, not that many levels or mechanics, but that's
fine. I always try to work towards a "minimum viable product" (or
"minimal publishable build", as I like to call it) first. I could submit
the game to the jam now and it would be fine, that's the idea.

But of course, we have some time for sound, particles, more content, so
let's go there.

### The magnet world

First up: the Attractor wizard.

At first, I wanted to code it like this:

-   It attracts the first thing it sees

-   But when inverted (number \< 0), it repels the first thing it sees.

But then I realized that this would be inconsistent with how all
entities moved until now. Inverting them turns them around, making them
look in the other direction.

So it was a better idea to keep that consistency:

-   It attracts the first thing it sees

-   When inverted, it just looks the other way, attracting the first
    thing it sees there.

This meant that "repelling" wasn't used, so I made that a different
wizard. This world therefore introduces two wizards, but they are so
similar that I thought it was okay.

I also, initially, thought the idea didn't work as well as I hoped. No
matter how long I kept the simulation running, it just wouldn't find
(good) puzzles.

Then I found out I'd forgotten to put the attraction code inside a loop
:p It only checked what was *right next to it*, instead of continuing
until it saw something (or went out of bounds).

With that fixed, good puzzles came back within 5-10 seconds, and all was
well.

### The knob world

There were two things holding back puzzles now:

-   Entities can't be rotated. That makes the solution more obvious
    *and* makes many puzzles fail ("no solution possible") in the
    simulation.

-   Knobs are randomly added and don't change, which has the same
    consequence.

I had to choose which one to address first. The "Rotate" entity only
makes sense as a *support* wizard ( = rotating others around it, instead
of itself). I wanted to hold out on those as long as possible, as they
are slightly more complex to explain and puzzle with.

So knobs it is!

The idea is simple:

-   Some cells randomly receive a knob, hovering above it.

-   Passing through that cell picks up the knob. (There's a general
    "knob inventory", probably in the top-left corner of the screen.)

-   Whenever you activate an entity, and you have a knob, it will be
    added *at the side you entered*.

As such, *you* are responsible for adding the knobs to entities at the
right positions. This leads to more open puzzles + less failed
simulations due to the random setup.

### More animations

By this point, some actions (which happen *a lot* in this game) were
looking a bit odd. Removing a bunny, for example, would just shove the
hat into the bunny, then slowly scale down the bunny.

That's not great.

So I spent (way too much) time creating custom animations to:

-   Lift the hat in advance

-   So the bunny moves under it

-   Then lower the hat to make the bunny disappear.

In the same vein, when a stack is changed (multiple hats on top of each
other), a new one pops up and does some "squash-and-stretch" animation
before landing on top.

It's not *amazing* yet, but already a huge improvement in the look and
feel of the game.

### The smaller ideas

By now, I wasn't sure if I'd have time to even add those support wizards
(properly). So I wanted to add some smaller ones first, which should
still be interesting:

-   **Jump:** instead of moving one block at a time (and possibly being
    stopped by something), it immediately jumps to its location

-   **Passthrough:** when 0, you can go **through** it without stopping.
    When it's loaded, it does stop you.

-   **Destruct:** when 0, nothing's wrong. When loaded positively, it
    kills itself. When loaded negatively, it kills you.

All of these reduce this big issue: because entities stop *whenever they
enter a cell with someone else*, movement is quite constricted in most
puzzles. Jumping, passing through, removing entities, all of them add
movement opportunities.

Another issue is also mitigated: it's too safe for the player now,
meaning that the solution is often a few simple clear lines through all
entities. By adding ways for the player to die (when entering an
entity), this gets more fuzzy.

**Remark:** the jumping entity did produce some nasty troubles for the
code. It doesn't repeat its action X times, it jumps X squares in one
go. The code wasn't set up for that and it took some time to cleanly
implement this as a variation (an "immediate execute").

In the end, the "passthrough" one really didn't pan out. I wasn't able
to find actually good puzzles with them. "Jumping", on the other hand,
is more powerful than I thought and therefore received its own little
world (before the others).

**Remark:** implementing these levels also allowed me some insight into
specific bugs I was having for days, finally able to solve them! Which
is nice. That's why it's sometimes better to leave bugs open and wait
for "more information" on them as you continue working on the project.

I tried to improve the "passthrough" (which was renamed to "Ghost"):

-   The ghost wizard stops you when its number is 0, as usual.

-   When negatively wound, you can't even enter its square

-   When positively wound, you can move through without stopping.

But it just didn't work out. At least, not in time for the jam deadline,
so I wanted to continue with something else.

### Support wizards

The past two days reminded me that it's just impossible to *predict* if
a certain idea will be fun (and will lead to good puzzles). As such, I'm
going to try to just implement **support wizards** (the 3 or 4 ideas I
had) at lightning speed and find out if something good comes from it.

These ideas are:

-   Rotator =\> rotates wizards around itself

-   Converter =\> converts wizards around itself (from good to bad, or
    vice versa)

-   Battery =\> winds up everything around itself

    -   When non-support, this also allows using the player to transport
        "energy". Entering the battery wizard then transfers its energy
        to *you*.

I had some more wild ideas (such as different types of *knobs* or a
wizard that literally *gives you extra turns* (or takes them)), but
those were just too much and I decided to leave them.

Do they work as well as I thought? **Yes.**

Adding the rotating wizard invigorates the game and suddenly makes all
puzzles feel different (both in look and solution). It's actually quite
amazing we managed to come all this way *without* being able to rotate
anything.

The converter is fun, albeit a bit hard to reason about as the player,
so if it appears, it will be as one of the final worlds.

The battery ... I'm not sure. Adding *another* number onto the
UI/player, another thing to calculate, it seems a bit too much. But it
does fit the theme really well and leads to the most complex puzzles of
all ...

A playtest
----------

I asked my little sister to test the game. (Or, well, at least the first
few worlds, which were completely done at the time.)

The result?

-   *Many* tiny fixes. (Levels in the wrong order, one level I put in
    the wrong world, etc.)

-   99% of the game was immediately clear, but there were *some*
    hiccups.

    -   For example, activation is taught in two images: Activate (I)
        and Activate (II). My sister, however, thought that "I" meant
        she had to press the *key "I"* to activate stuff. Confusing
        moments like that should be avoided at all costs.

    -   Or, the name of the world and level you're currently in are
        *never displayed on the level itself*. This made it very hard to
        know where you were, and when you transitioned into a new world.

-   *Some new ideas!*

My sister tried to stack one bunny onto another (to make two of them).
After trying it, she realized it wasn't possible and that she should do
it via *rotating the knobs*, which is *good*.

But it did make me wonder: would this be a good mechanic? It feels like
an intuitive thing to try, and it fits really well with the game and the
stacking bunny visuals.

So I decided "what the heck, let's add it as an option, and see what we
get"

Never mind, it's crisis time!
-----------------------------

Okay, stacking things was relatively easy to implement (thanks to my
Command system).

However, it revealed an issue to me:

-   In the *simulation*, it would do a complete cell evaluation after
    each move.

-   In the *game code*, after each move, it only evaluated if the cell
    *did anything with the entity that just moved*.

In many cases, these are the same. But not all cases, which I learnt
today. It's less than 2 days until the deadline ... and I'm afraid I
have to break open this crucial part of the code.

Here's what needs to change:

-   Rewrite the "on\_cell\_enter" function to evaluate the *whole cell*,
    no matter what entered it.

-   Don't run this function when the player is *dragged*. (This happens
    simultaneously with the entity that drags it, so it's enough if that
    entity does the evaluation.)

-   Create a way to make some commands "instant" (without animation or
    delay), so we can insta-swap models when two things stack on top of
    each other, making it look smooth.

    -   As we know, games are all *smoke and mirrors* :p When a bunny
        jumps on top of another ... the original one is killed, and the
        other one just *instantly* adds a new one on top. Way, way, way
        simpler to code and maintain, the only issue is making visuals
        that hide this transition.

I sincerely hope this doesn't break any of the 50+ puzzles I made before
this, as I don't have time to test them all again. (A quick test shows
no issues, but puzzle games can fail with only *one* tiny logic mistake
from my part ...)

Pfew, after a few hours of crisis coding, it seems that everything works
now. In fact, stacking is quite smooth, which I'm happy with.

This *does* mean I don't really have time left for the last few worlds I
had in mind. I just have to finish it up (logo, marketing page, icon,
last polish) and submit.

Finishing the thing
-------------------

The soundtrack was completed and added. Some basic marketing images were
made.

(Also because I was quite burned out after working so much in such
little time, there just wasn't inspiration and energy left for some
grand logo or icon.)

I wrote down exactly what I'd fix and add when the game jam was over ...
submitted it and went to bed for, like, three days :p (Nah, it's not
*that* bad as I know how to pace myself and stay healthy, but I did
allow myself one "rest day" after joining two game jams in a single
month with quite big games.)

### What do I think of this game?

As always, I'm a perfectionist. I never find anything I make good. But
that's why I've learnt to look at how *others* see it for my judgment.

The few people I asked to test the game, were very positive about it.
They immediately understood the puzzle mechanics, they thought the game
looked cute and simple, and usually played way longer than I asked them
to.

Looking at the game with some distance -- only the screenshots, the GIFs
I posted on Twitter during development, an overview of the worlds -- I
can see that it's quite the game. Many puzzles, well-paced, well
laid-out, a coherent aesthetic and idea.

Looking at those findings, I think this is a good game and can be
enjoyed by anyone, even long after the jam. It also taught me many
lessons:

-   How to code (better) puzzle simulations in Rust (the new programming
    language I wanted to learn). This simulation is *way faster,
    cleaner, more flexible than anything I wrote before (in Java).*

-   How to do 3D models, rotations, animations, levels, etcetera. Well,
    I mostly learnt what *not* to do. (I want to slowly move towards
    more 3D games, and this was a good first step.)

-   A better sense of how to pace puzzle elements, which ones to
    introduce when, and mostly to just *try it all out* and keep what
    sticks. (A previous puzzle game had *500* puzzles in the end. They
    were all good, but it was just way too much, and I should've stopped
    at 50-100 max.)

-   That posting your progress every two days on Twitter is a tiny thing
    with huge results. Many people started following the progress and
    subsequently tried my game when voting began.

### Why am I not superhappy?

**Reason 1:** The visuals are just a bit ... bland. That's partly due to
the time limit, partly due to my lack of experience with 3D. After a
while, all levels start to look identical, and it becomes boring to look
at the same models time and time again.

This can be solved with more time, more experience, and just adding
visual variations: environment around the puzzles, different (colored)
backgrounds, etcetera.

**Reason 2:** Some puzzles and mechanics just became "number crunching"
in the end. Those puzzles don't rely on a "Eureka" moment ( = a moment
of clever insight that allows you to find the solution, which is what
you want in a puzzle) ... they are solved by simply calculating and
predicting all the possibilities and finding the right one.

This can be solved by picking better mechanics and writing more (smart)
rules to force the random generation in a good direction. I was able to
implement *some* (10) rules to guide the simulation, but even my
previous puzzle game had more like 20-30 small rules to get smarter
puzzles.

**Reason 3:** It feels like, over the course of the game, we move away
from that concept of "rotating knobs to wind up entities"

Instead, the game just moves towards: here are X special entities, find
a way to activate them in the right order.

I should've only added mechanics that do something extremely unique and
special with the *winding up* idea and the *knobs.* That would've kept
it more unique and more ... coherent, I guess.

But hey, learned a lot from that, and will apply it to the next
(puzzle/3D) game I make.
