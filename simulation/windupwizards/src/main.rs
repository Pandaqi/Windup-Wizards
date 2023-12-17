use rand::prelude::*;
use rand::{distributions::Alphanumeric, Rng};
use rand_seeder::Seeder;
use rand_pcg::Pcg64;

use serde::*;
use std::fs::File;

use std::io::BufWriter;

type CellIndex = usize;
type EntityIndex = usize;

#[derive(Serialize, Deserialize)]
struct ExportData {
    width: usize,
    height: usize,
    cells: Vec<i8>,
    cell_contents: Vec<bool>,
    entities: Vec<Vec<ExportEntity>>,
    solution: Vec<usize>,
    config: ExportConfig
}

#[derive(Serialize, Deserialize)]
struct ExportEntity {
    kind: String,
    knobs: Vec<bool>,
    rot: usize,
    bad: bool,
    auto: bool,
    support: bool,
    number: i8,
}

#[derive(Serialize, Deserialize)]
struct ExportConfig {
    rev_wind: bool,
    man_act: bool,
    act_repeat: bool,
    p_drag: bool,
    drag_chain: bool,
    team_stack: bool,
    stop_after_enc: bool,
}

struct Cell {
    active: bool,
    player: bool,
    kind: usize
}

struct SpecialtyComponent {}

struct Entity {
    cell: CellIndex,
    kind: String,
    dead: bool,
    rot: usize,
    bad: bool,
    auto: bool,
    support: bool,
    activated: bool, // whether it's currently following an activation or not, to prevent repeat activations
}

impl Entity {
    fn new(cell: CellIndex, kind: String, rot: usize, bad: bool, support: bool, auto: bool) -> Self 
    {
        Self {
            cell,
            kind,
            dead: false,
            rot,
            bad,
            auto,
            support,
            activated: false
        }
    }
}

struct NumberComponent {
    val: i8
}

impl NumberComponent {
    fn new(val: i8) -> Self
    {
        Self {
            val
        }
    }

    fn count(&self) -> i8
    {
        return self.val;
    }

    fn change(&mut self, dp: i8)
    {
        self.val += dp;
    }

    fn at_max_capacity(&self, target: u8) -> bool
    {
        return (self.val.abs() as u8) >= target;
    }
}

struct KnobComponent {
    list: Vec<bool>,
    used: Vec<bool> // for statistics; whether it's actually used in the solution or not
}

impl KnobComponent {
    fn new() -> Self
    {
        Self {
            list: vec![false;4],
            used: vec![false;4]
        }
    }

    fn add(&mut self, index: usize) 
    {
        self.list[index] = true;
    }

    fn remove(&mut self, index: usize)
    {
        self.list[index] = false;
    }

    fn has(&self, index: usize) -> bool
    {
        return self.list[index];
    }

    fn turn(&mut self, index: usize)
    {
        self.used[index] = true;
    }

    fn count_unused(&self) -> u8
    {
        let mut sum : u8 = 0;
        for i in 0..4
        {
            if self.list[i] && !self.used[i] { sum += 1; }
        }
        return sum;
    }

    fn count_used(&self) -> u8
    {
        let mut sum : u8 = 0;
        for i in 0..4
        {
            if self.list[i] && self.used[i] { sum += 1; }
        }
        return sum;
    }

    fn get(&self) -> &Vec<bool>
    {
        return &self.list;
    }
}

struct Commands {
    list: Vec<Vec<Box<dyn Command>>>,
    cur_open_move: i8,
    command_names: Vec<String>
}

impl Commands {
    fn new() -> Self {
        Self { 
            list: Vec::new(),
            cur_open_move: -1,
            command_names: Vec::new()
        }
    }

    fn open_new_move(&mut self)
    {
        self.list.push(Vec::new());
        //println!("Num moves open {}", self.list.len());
        //println!("Cur open move {} ", self.cur_open_move);
        self.cur_open_move += 1
    }

    // This is short code, but crucial code
    // Commands that will fail may NEVER be executed, as there's no way for me to save that they failed, thus leading to undoing commands that were never done
    // Commands must be added to the list BEFORE being executed, otherwise they'll undo in the wrong order
    // The result MUST be kept and returned, or the player doesn't know when to stop its endless flight
    fn add_and_execute(&mut self, state: &mut State, cmd: Box<dyn Command>) -> CommandResult
    {
        if !cmd.is_valid(state) { return CommandResult { failed: true, stop: true }; }

        // first we reserve space at the right spot in the list
        let cur_move = self.cur_open_move as usize;
        let cur_index = self.list[cur_move].len();
        self.list[cur_move].push(Box::new(EmptyCommand { }));

        // then we execute the command
        let res = cmd.execute(state, self);

        // and then we put it where we wanted in the first place
        self.list[cur_move][cur_index] = cmd;
        if res.failed { return res; }

        return res;
    }

    // NOTE: we go through the commands in REVERSE, otherwise it wouldn't be a proper undo system
    fn pop_and_rollback(&mut self, state: &mut State)
    {
        let last_cmds = self.list.pop().unwrap();
        for cmd in last_cmds.iter().rev()
        {
            cmd.rollback(state, self);
        }

        self.cur_open_move -= 1;

        //println!("Num moves open {}", self.list.len());

    }
}

struct CommandResult {
    failed: bool,
    stop: bool
}

trait Command {
    fn is_valid(&self, state: &mut State) -> bool { return true; }
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult;
    fn rollback(&self, state: &mut State, commands: &mut Commands);
}

// In cases where the compiler or logic requires some default value; will always be overriden by the actual thing later
struct EmptyCommand {}
impl Command for EmptyCommand {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult
    {
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass
    }
}

// NOTE: This implementation is fixed to the PLAYER
// If I want others to use it, I need to generalize it (and check for is_player)
struct PosChange { idx: EntityIndex, dir: usize, num: i8 }
impl Command for PosChange {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let cur_idx = state.entities[self.idx].cell;

        let mut new_idx = GridHelper::get_cell_in_dir(state, cur_idx, self.dir).unwrap();
        if self.num.abs() > 1
        {
            new_idx = GridHelper::get_cell_in_dir_extended(state, cur_idx, self.dir, self.num).unwrap();
        }

        commands.add_and_execute(state, Box::new(GridTransfer { idx: self.idx, a: cur_idx, b: new_idx }));

        commands.add_and_execute(state, Box::new(CheckCellContent { idx: new_idx }));
        commands.add_and_execute(state, Box::new(CheckKnobs { idx: cur_idx, dir: self.dir }));
        commands.command_names.push(String::from("PosChange"));

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass => GridTransfer and CheckKnobs undo themselves
    }
}

struct Move {
    idx: EntityIndex,
    dir: usize,
    drag: bool,
    num: i8
}

impl Command for Move {
    fn is_valid(&self, state: &mut State) -> bool
    {
        let entity = self.idx;
        let cur_idx = state.entities[self.idx].cell;
        let mut new_idx = GridHelper::get_cell_in_dir(state, cur_idx, self.dir);
        if self.num > 1
        {
            new_idx = GridHelper::get_cell_in_dir_extended(state, cur_idx, self.dir, self.num);
        }

        if state.entities[self.idx].dead { return false; } // can't move dead entities
        if new_idx.is_none() || !MoveHelper::can_enter(state, entity, new_idx.unwrap()) // not allowed to move there
        {
            return false;
        }
        return true;
    }

    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let entity = self.idx;
        let cur_idx = state.entities[self.idx].cell;

        let mut new_idx = GridHelper::get_cell_in_dir(state, cur_idx, self.dir).unwrap();
        if self.num.abs() > 1
        {
            new_idx = GridHelper::get_cell_in_dir_extended(state, cur_idx, self.dir, self.num).unwrap();
        }

        let is_player : bool = entity == 0;

        // turn knobs on the things we glided past
        if is_player
        {
            commands.add_and_execute(state, Box::new(CheckKnobs { idx: cur_idx, dir: self.dir }));
        }

        // then check if we interact with the thing (to remove it or be removed)
        let mut must_stop : bool = MoveHelper::must_stop(state, entity, new_idx);
        if !is_player
        { 
            //
            // TO DO: Make all this an "Encounter" command?
            //
            let other_entity = state.cell_entity[new_idx];
            if !other_entity.is_none() {
                let they_are_bad = state.entities[other_entity.unwrap()].bad;
                let we_are_bad = state.entities[entity].bad;

                let same_team = (they_are_bad == we_are_bad);
                if same_team && state.config.team_stack_enabled 
                {
                    commands.add_and_execute(state, Box::new(Stack { giver: entity, receiver: other_entity.unwrap() }));
                    must_stop = true;
                }
                else if they_are_bad && !we_are_bad
                {
                    commands.add_and_execute(state, Box::new(Kill { idx: other_entity.unwrap(), remove_grid: true }));
                    must_stop = true;
                } 
                else if we_are_bad && !they_are_bad
                {
                    commands.add_and_execute(state, Box::new(Kill { idx: entity, remove_grid: false }));
                    must_stop = true;
                }
            }

            // If we hit a hole, kill ourselves
            if MoveHelper::cell_is_hole(state, new_idx)
            {
                commands.add_and_execute(state, Box::new(Kill { idx: entity, remove_grid: false }));
                must_stop = true;
            }   
        }

        // NOTE: if we were killed, this command will only remove us from our current cell, not add to new
        // NOTE: Conversely, if we killed something else, this command will just override them in the grid
        commands.add_and_execute(state, Box::new(GridTransfer { idx: entity, a: cur_idx, b: new_idx } ));

        // and always drag the player, if they were on our previous cell
        // a PosChange is a watered-down version of Move, because dragging doesn't activate most stuff, AND is certain to succeed
        if !is_player && state.cells[cur_idx].player && state.config.player_dragging_enabled
        {
            commands.add_and_execute(state, Box::new(PosChange { idx: 0, dir: self.dir, num: self.num }));
        }

        if is_player {
            commands.add_and_execute(state, Box::new(CheckCellContent { idx: new_idx }));
        }

        // if our final cell holds both an ENTITY and the PLAYER, try activating it
        // (the entity might have number 0 or already be activated, so nothing happens, hence "try")
        // also give it a knob at the side we entered
        if !state.cell_entity[new_idx].is_none() && state.cells[new_idx].player
        { 
            if state.config.player_activates_by_entering && state.config.allow_drag_chaining
            {
                let entity_idx = state.cell_entity[new_idx].unwrap();
                commands.add_and_execute(state, Box::new(CheckKnobAddition { idx: entity_idx, dir: self.dir, is_player: is_player }));

                commands.add_and_execute(state, Box::new(TransferPointsFromPlayer { idx: entity_idx }));

                let mut activate_command : Box<dyn Command>;
                if state.entities[entity_idx].support {
                    activate_command = Box::new(SupportActivate { idx: entity_idx });
                } else {
                    activate_command = Box::new(Activate { idx: entity_idx, o: false, o_dir: 0, o_num: 0, o_kind: "".to_string() });
                }

                commands.add_and_execute(state, activate_command);
            }
        }

        // if we're not forced to stop after encounters, then we just continue (given we're not dead)
        if !state.config.stop_after_encounter {
            if !state.entities[entity].dead {
                must_stop = false;
            }
        }

        return CommandResult { failed: false, stop: must_stop }
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // this function only adds new commands; will be undone by itself
    }
}

struct GridTransfer { idx: EntityIndex, a: CellIndex, b: CellIndex }
impl Command for GridTransfer {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        // always save the move on the ENTITY 
        // (but not necessarily on the grid, as dead entities are off-grid)
        let entity = self.idx;
        let is_player = entity == 0;
        state.entities[entity].cell = self.b;

        if is_player {
            state.cells[self.a].player = false;
        } else {
            state.cell_entity[self.a] = None;
        }

        if state.entities[entity].dead { return CommandResult { failed: false, stop: false }; }

        // if we're still alive and well, finish the movement
        if is_player
        {
            state.cells[self.b].player = true;
            state.cells_used[self.b] = true;
        } else {
            state.cell_entity[self.b] = Some(entity);
        }

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        let entity = self.idx;
        let is_player = entity == 0;
        state.entities[entity].cell = self.a;

        if is_player {
            state.cells[self.a].player = true;
        } else {
            state.cell_entity[self.a] = Some(entity);
        }

        if state.entities[entity].dead { return; }
        
        if is_player {
            state.cells[self.b].player = false;
        } else {
            state.cell_entity[self.b] = None;
        }
        
    }
}

struct TransferPointsFromPlayer { idx: EntityIndex }
impl Command for TransferPointsFromPlayer {
    fn is_valid(&self, state: &mut State) -> bool
    {
        // if nothing to transfer, the command isn't valid
        return (state.player_number != 0)
    }

    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult
    {
        let cur_player_num = state.player_number;
        let mut change_dir = 1;
        if cur_player_num < 0 { change_dir = -1; }

        // give us all points 
        // (do so individually, per point, using TurnKnob => works better with command system)
        for i in 0..cur_player_num.abs() {
            commands.add_and_execute(state, Box::new(TurnKnob { e_idx: self.idx, change_dir: change_dir }));
        }

        // then pay for that by completely emptying the player number
        // (again, doing it this way, works better and gives us easy undo)
        commands.add_and_execute(state, Box::new(ChangePlayerNumber { val: -cur_player_num }));

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass -> only new commands added
    }
}

struct ChangePlayerNumber { val: i8 }
impl Command for ChangePlayerNumber {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult
    {
        state.player_number += self.val;
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        state.player_number -= self.val;
    }
}

struct Battery { idx: EntityIndex, o: bool, o_num: i8 }
impl Command for Battery {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let entity = self.idx;

        // if we're not receiving another battery (through support), we pay the player
        if !self.o {
            
            let cell_idx = state.entities[entity].cell;
            let mut my_num = state.entity_numbers[entity].count();
            if my_num > 0 { my_num = 1; }
            else if my_num < 0 { my_num = -1; }

            if state.cells[cell_idx].player {
                commands.add_and_execute(state, Box::new(ChangePlayerNumber { val: my_num }));
            }
        
        // otherwise, we RECEIVE points from the other one
        } else {
            let mut change_dir = 1;
            if self.o_num < 0 { change_dir = -1; }
            
            commands.add_and_execute(state, Box::new(TurnKnob { e_idx: entity, change_dir: change_dir }));
        }

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass; only commands
    }
}

struct Convert { idx: EntityIndex }
impl Command for Convert {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let old_val = state.entities[self.idx].bad;
        let mut change_dir = 1;
        if old_val { change_dir = -1; } // if we used to be bad, the number of bad entities goes -1

        state.entities[self.idx].bad = !old_val;

        commands.add_and_execute(state, Box::new(BadEntityChange { val: change_dir }));

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        let old_val = state.entities[self.idx].bad;
        state.entities[self.idx].bad = !old_val;

        // the BadEntityChange command will be undone on its own
    }
}

struct Rotate { idx: EntityIndex, num: i8 }
impl Command for Rotate {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let mut change_dir : usize = 1;
        if self.num < 0 { change_dir = 3; }

        state.entities[self.idx].rot = (state.entities[self.idx].rot + change_dir) % 4;
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        let mut change_dir : usize = 3;
        if self.num < 0 { change_dir = 1; }

        state.entities[self.idx].rot = (state.entities[self.idx].rot + change_dir) % 4;
    }
}

struct Destruct { idx: EntityIndex, num: i8 }
impl Command for Destruct {
    fn is_valid(&self, state: &mut State) -> bool
    {
        if state.entities[self.idx].dead { return false; }
        if self.num == 0 { return false; }
        return true;
    }

    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        // Positively wound up? We kill ourselves
        if self.num > 0 
        {
            commands.add_and_execute(state, Box::new(Kill{ idx: self.idx, remove_grid: true }));
        
        // Negatively wound up? We kill the player, if he's here
        } else {
            if state.cells[state.entities[self.idx].cell].player {
                commands.add_and_execute(state, Box::new(Kill{ idx: 0, remove_grid: true }));
            }
        }
        
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands) { /* pass */ }
}

struct Jump { idx: EntityIndex, dir: usize, num: i8 }
impl Command for Jump {
    fn is_valid(&self, state: &mut State) -> bool
    {
        let entity_idx = self.idx;
        let cell = state.entities[entity_idx].cell;
        let absolute_num = self.num.abs();
        let new_pos = GridHelper::get_cell_in_dir_extended(state, cell, self.dir, absolute_num);
        if new_pos.is_none() { return false; }
        if !MoveHelper::can_enter(state, entity_idx, new_pos.unwrap()) { return false; }
        return true;
    }

    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let absolute_num = self.num.abs();
        commands.add_and_execute(state, Box::new(Move { idx: self.idx, dir: self.dir, drag: false, num: absolute_num }));
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands) { /* pass */ }
}

struct AddKnob { idx: EntityIndex, dir: usize }
impl Command for AddKnob {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        state.entity_knobs[self.idx].add(self.dir);
        state.player_knobs -= 1;
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        state.entity_knobs[self.idx].remove(self.dir);
        state.player_knobs += 1;
    }
}

struct PickupKnob { idx: CellIndex }
impl Command for PickupKnob {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        state.player_knobs += 1;
        state.cell_knob[self.idx] = false;
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        state.cell_knob[self.idx] = true;
        state.player_knobs -= 1;
    }
}

struct CheckCellContent { idx: CellIndex }
impl Command for CheckCellContent {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let cell_has_knob = state.cell_knob[self.idx];
        if cell_has_knob
        {
            commands.add_and_execute(state, Box::new(PickupKnob { idx: self.idx } ));
        }
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass; execute only adds commands
    }
}

struct CheckKnobAddition { idx: EntityIndex, dir: usize, is_player: bool }
impl Command for CheckKnobAddition {
    fn is_valid(&self, state: &mut State) -> bool
    {
        let entity = self.idx;
        let currently_activated = state.entities[entity].activated;
        if currently_activated { return false; }

        let is_dead = state.entities[entity].dead;
        if is_dead { return false; }

        return true;
    }

    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {           
        let entity_idx = self.idx;
        let entity_rot = state.entities[entity_idx].rot;
        
        let mut approach_dir = self.dir;
        if self.is_player { approach_dir = (approach_dir + 2) % 4; }
        let global_approach_dir = (approach_dir + 4 - entity_rot) % 4;

        if state.player_knobs > 0 && !state.entity_knobs[entity_idx].has(global_approach_dir)
        {
            commands.add_and_execute(state, Box::new(AddKnob { idx: entity_idx, dir: global_approach_dir }));
        }
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass; execute only adds commands
    }
}

struct CheckKnobs { idx: CellIndex, dir: usize }
impl Command for CheckKnobs {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let our_coords = GridHelper::get_cell_coords(state, self.idx);
        let dir_vec = GridHelper::get_dir_as_vec(self.dir);

        let right_vec = (-dir_vec.1, dir_vec.0);
        let right_coords = (our_coords.0 + right_vec.0, our_coords.1 + right_vec.1);
        let right_dir = (self.dir + 1) % 4;

        // @params state, commands, cell, CW or CCW?, knob_dir
        MoveHelper::rotate_knob_at(state, commands, GridHelper::get_cell_index(state, right_coords.0, right_coords.1), 1, right_dir);

        if !state.config.reverse_winding_up_allowed
        {
            return CommandResult { failed: false, stop: false };
        }

        let left_vec = (dir_vec.1, -dir_vec.0);
        let left_coords = (our_coords.0 + left_vec.0, our_coords.1 + left_vec.1);
        let left_dir = (self.dir + 4 - 1) % 4;

        MoveHelper::rotate_knob_at(state, commands, GridHelper::get_cell_index(state, left_coords.0, left_coords.1), -1, left_dir);

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass; execute only adds commands
    }
}

struct Stack { giver: EntityIndex, receiver: EntityIndex }
impl Command for Stack {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        // the giver is drained completely
        let num_points_giver = state.entity_numbers[self.giver].count();
        commands.add_and_execute(state, Box::new(TurnKnob { e_idx: self.giver, change_dir: -num_points_giver }));

        // then dies
        // (this only happens inside a Move command, which will take care of the "remove from grid" part)
        commands.add_and_execute(state, Box::new(Kill { idx: self.giver, remove_grid: false }));

        // the receiver gets those points
        // but only to EXTEND their current direction, not the strict mathematical sense 
        // (as it'd be too complicated and not intuitive with how the game is visualized)
        let num_points_receiver = state.entity_numbers[self.receiver].count();
        let mut dir = 1;
        if num_points_receiver < 0 { dir = -1; }
        let points_for_receiver = num_points_giver.abs() * dir;

        commands.add_and_execute(state, Box::new(TurnKnob { e_idx: self.receiver, change_dir: points_for_receiver }));

        state.times_stacked += 1;

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass; only adds commands
    }
}

struct TurnKnob { e_idx: EntityIndex, change_dir: i8 }
impl Command for TurnKnob {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        state.entity_numbers[self.e_idx].change(self.change_dir);
        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        state.entity_numbers[self.e_idx].change(-self.change_dir);
    }
}

struct Attract { idx: EntityIndex, dir: usize, repel: bool }
impl Command for Attract {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let grid_pos = state.entities[self.idx].cell;
        let target = GridHelper::find_first_entity_in_dir(state, grid_pos, self.dir);
        if target.is_none() { return CommandResult { failed: true, stop: true }; }

        let mut rev_dir = (self.dir + 2) % 4;
        if self.repel { rev_dir = self.dir; }

        let res = commands.add_and_execute(state, Box::new(Move { idx: target.unwrap(), dir: rev_dir, drag: false, num: 1 }));
        return res;
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // execute adds a single command or nothing, so no need to do anything here
    }
}

struct SupportActivate { idx: EntityIndex }
impl Command for SupportActivate {
    fn is_valid(&self, state: &mut State) -> bool
    {
        if state.success { println!("Trying to activate SUPPORT"); }

        let entity = self.idx;
        let is_dead = state.entities[entity].dead;
        if is_dead { return false; }

        let number = state.entity_numbers[entity].count();
        if number == 0 { return false; }

        return true;
    }
    
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        if state.success { println!("Support activated!"); }

        state.num_support_used += 1;

        let my_cell = state.entities[self.idx].cell;

        let dir = state.entities[self.idx].rot;
        let kind = state.entities[self.idx].kind.clone();

        loop {
            let num = state.entity_numbers[self.idx].count();

            let mut num_stops : u8 = 0;
            let mut num_fails : u8 = 0;
            let mut num_executed : u8 = 0;

            for i in 0..4
            {
                let cell = GridHelper::get_cell_in_dir(state, my_cell, i);
                if cell.is_none() { continue; }

                let cell = cell.unwrap();
                if state.cell_entity[cell].is_none() { continue; }

                let entity = state.cell_entity[cell].unwrap();
                let activate_command = Box::new(Activate { idx: entity, o: true, o_dir: dir, o_num: num, o_kind: kind.clone() });
                let res = commands.add_and_execute(state, activate_command);

                num_executed += 1;
                if res.failed { num_fails += 1; }
                if res.stop { num_stops += 1; }
            }

            if state.success {
                println!("Num executed {}", num_executed);
                println!("Num fails {}", num_fails);
            }

            let failed = (num_fails >= num_executed);
            let stop = (num_stops >= num_executed);

            if !failed {
                let mut knob_change_dir = -1;
                if num < 0 { knob_change_dir = 1; }

                commands.add_and_execute(state, Box::new(TurnKnob { e_idx: self.idx, change_dir: knob_change_dir }));
                state.entities_used[self.idx] = true;
            }
            
            if failed || stop || num == 0 {
                break;
            }
        }

        return CommandResult { failed: false, stop: false };
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass; only adds new commands, will be rolled back automatically
    }
}

struct Activate { idx: EntityIndex, o: bool, o_dir: usize, o_num: i8, o_kind: String }
impl Activate {
    fn select_command(&self, state: &mut State, num: i8, invert: bool) -> Box<dyn Command>
    {
        let entity : EntityIndex = self.idx;
        let mut kind : String = state.entities[entity].kind.clone();
        if self.o { kind = self.o_kind.clone(); }

        let mut dir : usize = state.entities[entity].rot;
        if self.o { dir = self.o_dir; }
        if invert { dir = (dir + 2) % 4; }

        let mut cmd : Box<dyn Command> = Box::new(EmptyCommand {});

        let override_battery = self.o;

        // IMPORTANT: This is where we create/select different commands to be executed
        //            based on the wizard type
        match kind.as_str() 
        {
            "move" => { cmd = Box::new(Move { idx: entity, dir: dir, drag: false, num: 1 }); }
            "attract" => { cmd = Box::new(Attract { idx: entity, dir: dir, repel: false }); }
            "repel" => { cmd = Box::new(Attract { idx: entity, dir: dir, repel: true }); }
            "destruct" => { cmd = Box::new(Destruct { idx: entity, num: num }); }
            "jump" => { cmd = Box::new(Jump { idx: entity, dir: dir, num: num }); }
            "rotate" => { cmd = Box::new(Rotate { idx: entity, num: num }); }
            "convert" => { cmd = Box::new(Convert { idx: entity }); }
            "battery" => { cmd = Box::new(Battery { idx: entity, o: override_battery, o_num: num }); }
            _ => { println!("Something went wrong! Unknown type wizard activated."); }
        };

        return cmd;
    }
}

impl Command for Activate {
    fn is_valid(&self, state: &mut State) -> bool
    {
        let entity = self.idx;
        let already_activated = state.entities[entity].activated;
        let is_dead = state.entities[entity].dead;
        if already_activated { return false; }
        if is_dead { return false; }

        let mut number = state.entity_numbers[entity].count();
        if self.o { number = self.o_num; }
        if number == 0 { return false; }
        
        let mut kind = state.entities[entity].kind.clone();
        if self.o { kind = self.o_kind.clone(); }

        // passthrough cannot be _activated_ in any case
        if kind == "passthrough" { 
            state.entities_used[entity] = true; // but still count it as an activated entity for the statistics
            return false; 
        }
        if kind == "jump" && number.abs() <= 1 { return false; } // no sense in being a jumper if we're only moving one space

        return true;
    }

    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let entity = self.idx;
        state.entities[entity].activated = true;

        let mut number = state.entity_numbers[entity].count();
        if self.o { number = self.o_num }

        let invert = if number < 0 { true } else { false };

        let mut num_executions = number.abs();
        let sign = if number > 0 { 1 } else { -1 };

        let mut knob_change_dir = -sign;

        let mut kind = state.entities[entity].kind.clone();
        if self.o { kind = self.o_kind.clone(); }

        let is_immediate_effect = kind == "jump" || !state.config.activation_repeating_enabled;
        if is_immediate_effect
        {
            num_executions = 1;
            knob_change_dir = -sign * number.abs();
        }

        if self.o { num_executions = 1; }

        let mut res : CommandResult = CommandResult { failed: false, stop: false };
        for i in 0..num_executions {
            let cmd = self.select_command(state, number, invert);
            res = commands.add_and_execute(state, cmd);

            // if we did something, pay for it by unturning the knobs
            // (but only if we did it ourself, not forced by support)
            if !res.failed { 
                if !self.o {
                    commands.add_and_execute(state, Box::new(TurnKnob { e_idx: entity, change_dir: knob_change_dir }));
                }
                state.entities_used[entity] = true; 
            }
            if res.stop { break; }
        }

        state.entities[entity].activated = false;

        return CommandResult { failed: res.failed, stop: res.stop }
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        // pass; only adds new commands, will be rolled back automatically
    }
}

struct Kill { idx: EntityIndex, remove_grid: bool }
impl Command for Kill {
    fn is_valid(&self, state: &mut State) -> bool
    {
        if state.entities[self.idx].dead { return false; }
        return true;
    }

    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        let entity = self.idx;
        let is_player = (entity == 0);
        state.entities[entity].dead = true;

        let cell = state.entities[entity].cell;

        // only some Kill commands remove the entity
        // => when we exterminate something else, that something else needs to remember it's been thrown out of the grid
        // => if we kill ourselves in a move, the GridTransfer command takes care of that and just doesn't add us at the destination
        if self.remove_grid { 
            if is_player {
                state.cells[cell].player = false;
            } else {
                state.cell_entity[cell] = None;
            }
        }

        // for keeping track of our win condition as we go, so we don't need to recalculate it all the time
        // has no gameplay impact whatsoever
        if state.entities[entity].bad
        {
            commands.add_and_execute(state, Box::new(BadEntityChange { val: -1 }));
        }
        
        return CommandResult { failed: false, stop: false }
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        let entity = self.idx;
        let is_player = (entity == 0);
        state.entities[entity].dead = false;

        let cell = state.entities[entity].cell;

        // only add us back to the cell if we originally removed it
        if self.remove_grid { 
            if is_player {
                state.cells[cell].player = true;
            } else {
                state.cell_entity[cell] = Some(entity);
            }
        }

        // NOTE: the "BadEntityChange" command undoes itself
    }
}

struct BadEntityChange { val: i8 }
impl Command for BadEntityChange {
    fn execute(&self, state: &mut State, commands: &mut Commands) -> CommandResult 
    {
        state.bad_entities += self.val;
        return CommandResult { failed: false, stop: false }
    }

    fn rollback(&self, state: &mut State, commands: &mut Commands)
    {
        state.bad_entities -= self.val;
    }
}

#[derive(Clone)]
struct SimulationConfig {
    move_debug: bool,

    width: usize,
    height: usize,

    min_moves: usize,
    max_moves: usize,
    max_best_solutions: u8,

    move_dirs: Vec<(i8,i8)>,
    max_move_options: usize,

    max_states_allowed: u32,
    point_heuristic: f32,

    cell_disable_prob: f32,
    knob_add_prob: f32,
    loose_knob_prob: f32,
    no_outward_knobs: bool,

    // custom rules to turn on/off, so things are gradually introduces
    reverse_winding_up_allowed: bool,
    player_activates_by_entering: bool,
    activation_repeating_enabled: bool,
    player_dragging_enabled: bool,
    team_stack_enabled: bool,
    stop_after_encounter: bool,

    allow_drag_chaining: bool,
    forbid_knobs_on_bunnies: bool,
    bunnies_only_move: bool,
    dont_count_bad_in_used_entities: bool,

    cell_types: Vec<usize>,

    entity_types: Vec<String>,
    required_entity_types: Vec<String>,
    entity_num: (usize, usize),

    bad_prob: f32,
    bad_min: usize,

    good_min: usize,

    support_prob: f32,
    support_min: usize,

    auto_prob: f32,
    auto_min: usize,

    entity_starting_points_max: u8,
    total_points_max: u8,
    player_can_have_points: bool,

    cell_used_ratio: f32,
    entity_used_ratio: f32
}

struct State {
    seed: String,
    config: SimulationConfig,

    cells: Vec<Cell>,
    cell_entity: Vec<Option<EntityIndex>>,
    cell_knob: Vec<bool>,

    entities: Vec<Entity>,
    entity_numbers: Vec<NumberComponent>,
    entity_knobs: Vec<KnobComponent>,

    bad_entities: i8,
    success: bool,
    solution: Vec<usize>,

    cells_used: Vec<bool>,
    entities_used: Vec<bool>,
    times_stacked: usize,
    num_support_used: usize,

    player_knobs: usize,
    player_number: i8
}

impl State {
    fn new(config: SimulationConfig) -> Self
    {
        Self {
            seed: String::new(),
            config,
            cells: Vec::new(),
            cell_entity: Vec::new(),
            cell_knob: Vec::new(),

            entities: Vec::new(),
            entity_numbers: Vec::new(),
            entity_knobs: Vec::new(),

            bad_entities: 0,
            success: false,
            solution: Vec::new(),

            cells_used: Vec::new(),
            entities_used: Vec::new(),
            times_stacked: 0,
            num_support_used: 0,

            player_knobs: 0,
            player_number: 0
        }
    }

    fn reset_statistics(&mut self)
    {
        for i in 0..self.cells_used.len()
        {
            self.cells_used[i] = false;
        }

        for i in 0..self.entities_used.len()
        {
            self.entities_used[i] = false;
        }

        for i in 0..self.entity_knobs.len()
        {
            for a in 0..4
            {
                self.entity_knobs[i].used[a] = false;
            }
        }

        self.times_stacked = 0;
        self.num_support_used = 0;
    }
}

struct Generator {}

impl Generator {
    fn create_board(&mut self, state: &mut State)
    {
        let seed: String = rand::thread_rng()
            .sample_iter(&Alphanumeric)
            .take(4)
            .map(char::from)
            .collect();
        
        state.seed = seed.clone();

        let mut rng: Pcg64 = Seeder::from(seed).make_rng();

        self.create_cells(state, &mut rng);
        self.disable_random_cells(state, &mut rng);
        self.place_entities(state, &mut rng);
        self.distribute_knobs_over_cells(state, &mut rng);
    }

    fn create_cells(&mut self, state: &mut State, rng: &mut Pcg64) 
    {
        let mut cell_types : Vec<usize> = Vec::new();
        let num_cells = state.config.height * state.config.width;
        while cell_types.len() < num_cells 
        {
            let rand_type : usize = *state.config.cell_types.choose(rng).unwrap();
            cell_types.push(rand_type);
        }

        println!("Cell types {:?}", cell_types);

        let mut counter = 0;
        for y in 0..state.config.height {
            for x in 0..state.config.width {
                state.cells.push(Cell { active: true, player: false, kind: cell_types[counter] });
                state.cell_entity.push(None);
                state.cell_knob.push(false);
                state.cells_used.push(false);
                counter += 1;
            } 
        }
    }

    fn disable_random_cells(&self, state: &mut State, rng: &mut Pcg64)
    {
        if state.config.cell_disable_prob <= 0.01 { return; }
        for i in 0..state.cells.len()
        {
            let prob : f32 = rng.gen();
            if prob > state.config.cell_disable_prob { continue; }
            state.cells[i].active = false;
        }
    }

    fn distribute_knobs_over_cells(&self, state: &mut State, rng: &mut Pcg64)
    {
        if state.config.loose_knob_prob <= 0.01 { return; }
        for i in 0..state.cells.len()
        {   
            let prob : f32 = rng.gen();
            if prob > state.config.loose_knob_prob { continue; }
            if !state.cells[i].active { continue; }
            if !state.cell_entity[i].is_none() { continue; }
            if state.cells[i].player { continue; }
            
            state.cell_knob[i] = true;
        }
    }

    fn place_entities(&mut self, state: &mut State, rng: &mut Pcg64)
    {
        println!("Should place entities here");

        let num_entities : usize = rng.gen_range(state.config.entity_num.0 .. (state.config.entity_num.1 + 1));

        //
        // Entity TEAMS (good/bad)
        //
        let mut bad : Vec<bool> = Vec::new();
        bad.push(false);
        
        for i in 0..state.config.bad_min
        {
            bad.push(true);
        }

        for i in 0..state.config.good_min
        {
            bad.push(false);
        }

        while bad.len() < num_entities
        {
            let mut val = false;
            let prob : f32 = rng.gen();
            if prob <= state.config.bad_prob { val = true; }
            bad.push(val);
        }

        
        //
        // Entity TYPES
        //
        let mut types : Vec<String> = Vec::new();
        types.push(String::from("player"));

        let bunnies_only_move = state.config.bunnies_only_move;
        let mut counter = types.len();
        let mut req_types = state.config.required_entity_types.clone();

        loop
        {
            if (req_types.len() <= 0 || counter >= num_entities || types.len() >= num_entities) { break; }

            if bunnies_only_move && bad[counter] { 
                let rand_type : String = state.config.entity_types.choose(rng).unwrap().clone();
                types.push(rand_type);
                counter += 1;
                continue;
            }

            let kind = req_types.pop().unwrap().clone();
            types.push(kind);
            counter += 1;
        }
        
        while types.len() < num_entities
        {
            let rand_type : String = state.config.entity_types.choose(rng).unwrap().clone();
            types.push(rand_type);
        }
        
        //
        // Entity SUPPORT 
        //
        let mut support : Vec<bool> = Vec::new();
        support.push(false);

        for i in 0..state.config.support_min
        {
            support.push(true);
        }

        while support.len() < num_entities
        {
            let mut val = false;
            let prob : f32 = rng.gen();
            if prob <= state.config.support_prob { val = true; }
            support.push(val);
        }

        //
        // Entity AUTO ACTIVATORS
        //
        let mut auto : Vec<bool> = Vec::new();
        auto.push(false);

        for i in 0..state.config.auto_min
        {
            auto.push(true);
        }

        while auto.len() < num_entities
        {
            let mut val = false;
            let prob : f32 = rng.gen();
            if prob <= state.config.auto_prob { val = true; }
            auto.push(val);
        }

        //
        // Finally, actually create them
        //
        for i in 0..num_entities
        {
            self.place_entity(state, types[i].clone(), bad[i], support[i], auto[i], rng);
        }
        
    }

    fn place_entity(&mut self, state: &mut State, kind: String, bad: bool, support: bool, auto: bool, rng: &mut Pcg64)
    {
        let entity_idx = state.entities.len();
        let is_player = entity_idx == 0;

        let cell_idx = GridHelper::get_empty_cell(state, rng, is_player);
        if cell_idx.is_none() { return; }
        let cell_idx = cell_idx.unwrap();

        let rand_rot : usize = rng.gen_range(0..4);
        let mut final_kind = kind;
        if bad && state.config.bunnies_only_move { final_kind = String::from("move"); }
        let is_jumper = (final_kind == "jump");
        let is_destruct = (final_kind == "destruct");
        let is_passthrough = (final_kind == "passthrough");
        let is_battery = (final_kind == "battery");

        let mut final_support = support;

        // TO DO: Better way to (generally) force the "support" parameter on certain types
        // (Maybe an array "forced_support_types", check if current type is in that array?)
        if final_kind == "rotate" { final_support = true; }
        if final_kind == "jump" { final_support = false; } // can never be support
        if is_passthrough { final_support = false; } // can never be support

        // DEBUGGING => TEMPORARY => to test support batteries
        // if is_battery { final_support = true; }

        let entity = Entity::new(cell_idx, final_kind, rand_rot, bad, final_support, auto);
        if bad { state.bad_entities += 1; }

        state.entities.push(entity);
        state.entities_used.push(false);

        let mut knobs = KnobComponent::new();
        let mut possible_knobs = Vec::new();
        for i in 0..4
        {
            if is_player { continue; }
            if bad && state.config.forbid_knobs_on_bunnies { continue; }
            if state.config.no_outward_knobs && GridHelper::knob_points_at_nothing(state, cell_idx, rand_rot, i) { continue; }
            possible_knobs.push(i);
        }

        let num_possible_knobs = possible_knobs.len();
        if num_possible_knobs > 0 && state.config.knob_add_prob > 0.01
        {
            possible_knobs.shuffle(rng);
            let mut num_knobs : usize = 1; 
            if num_possible_knobs > 1 { num_knobs = rng.gen_range(1..possible_knobs.len()); }

            // because passthroughs might block player from entering, it's vital they get quite some knobs
            if is_passthrough {
                num_knobs = rng.gen_range(2..4);
                possible_knobs = vec![0,1,2,3];
                possible_knobs.shuffle(rng);
            }
            
            for i in 0..num_knobs {
                knobs.add(possible_knobs[i]);
            }
        }

        state.entity_knobs.push(knobs);

        let mut starting_range : u8 = 0;
        if state.config.entity_starting_points_max > 0 { starting_range = rng.gen_range(0..(state.config.entity_starting_points_max + 1)); }
        
        let mut starting_num : i8 = starting_range as i8;
        if rng.gen::<f32>() <= 0.5 { starting_num *= -1; }
        if is_player && !state.config.player_can_have_points { starting_num = 0; }
        if is_jumper { 
            if starting_num > 0 { starting_num += 1; }
            else { starting_num -= 1; }
        }

        // DEBUGGING/TEMPORARY: to get more interesting passthroughs or destructs
        if false {
            if is_destruct { 
                if starting_num > 0 { starting_num *= -1; }
            }

            if is_passthrough {
                if starting_num == 0 { starting_num = -1; }
                if starting_num > 0 { starting_num *= -1; }
            }

            if is_battery {
                if starting_num == 0 { starting_num = 1; }
            }
        }

        state.entity_numbers.push(NumberComponent::new(starting_num));

        let is_player = entity_idx == 0;
        if is_player
        {
            state.cells[cell_idx].player = true;
            state.cells_used[cell_idx] = true;
        } else {
            state.cell_entity[cell_idx] = Some(entity_idx);
        }
     
    }
}

struct Simulator {}

impl Simulator {

    fn try_all_moves(&self, state: &mut State)
    {
        let mut cur_move_per_layer : Vec<usize> = vec![0;state.config.max_moves]; // initialize all zeroes
        let mut cur_move_layer : usize = 0; 

        let mut success : bool = false;
        let mut count_num_states : u32 = 0;

        let mut commands : Commands = Commands::new();
        let mut solutions : Vec<Vec<usize>> = Vec::new();

        'outer_loop: loop {

            //println!("{:?}", cur_move_per_layer);

            // grab the current move we'd like to try, and try it
            let cur_move = cur_move_per_layer[cur_move_layer];
            let valid_move = MoveHelper::is_valid_move(state, 0, cur_move);
            let mut end_state = false;

            if valid_move
            {
                count_num_states += 1;
                self.do_move(state, &mut commands, cur_move);
            }

            // already update it, so the NEXT move is tried the next time we visit this
            cur_move_per_layer[cur_move_layer] += 1;

            if valid_move 
            {

                if self.in_loss_state(state) { 
                    //println!("ABORT. We lost.");
                    end_state = true;
                    success = false;
                }
                
                // abort if we're done
                if !end_state && self.in_win_state(state) { 
                    end_state = true;
                    success = true; 

                    // the saved solution is always 1 too high 
                    // (as it updates the move layer to the next after doing the move)
                    let mut solution = Vec::new();
                    for i in 0..cur_move_per_layer.len()
                    {
                        if cur_move_per_layer[i] == 0 { break; }
                        solution.push(cur_move_per_layer[i]-1);
                    }
                    solutions.push(solution);
                }

                // abort if some other check/heuristic fails
                if self.max_states_exceeded(state, count_num_states)
                {
                    println!("ABORT. Exceeded max number of states");
                    break;
                }

                if self.point_heuristic_failed(state, cur_move_layer)
                {
                    end_state = true;
                    println!("ABORT. Point heuristic failed.");
                }
            }

            // if there IS a deeper node, which we HAVEN'T CHECKED yet, go deeper
            // we don't allow this if we didn't actually move (valid_move = false)
            // or we've reached some end state (win/dead) and shouldn't continue further
            let deeper_node_exists = cur_move_layer < (state.config.max_moves - 1) && cur_move_per_layer[cur_move_layer + 1] < state.config.max_move_options;
            if deeper_node_exists && valid_move && !end_state
            {
                cur_move_layer += 1;
                continue;
            }

            // otherwise, undo the move we just did
            if valid_move {
                self.undo_last_move(state, &mut commands);
            }

            // then check where we need to go
            'inner_loop: loop {
                // if there are still more moves to try on this layer, try them immediately
                // (by breaking here, we stay on the same layer, and just go to the top of outer_loop again)
                let cur_move = cur_move_per_layer[cur_move_layer];
                if cur_move < state.config.max_move_options { break 'inner_loop; }

                // if we can't go back any further, quit completely
                if cur_move_layer == 0 { break 'outer_loop; }

                // otherwise, go back a layer, restart ourselves from 0 again
                cur_move_per_layer[cur_move_layer] = 0;
                cur_move_layer -= 1;
                self.undo_last_move(state, &mut commands);

                if cur_move_per_layer[cur_move_layer] < state.config.max_move_options { break 'inner_loop; }
            }
        }

        println!("Num states checked: {}", count_num_states);

        if !success { 
            println!("ABORT. No solution found.");
            return; 
        }

        println!("Num solutions: {}", solutions.len());

        // find the BEST solution out of all of them
        // and how many there exist (more of them = easier puzzle)
        let mut best_solution : Vec<usize> = solutions[0].clone();
        let mut best_solution_length : usize = 1000;
        let mut num_best_solutions : u8 = 0;
        for i in 0..solutions.len()
        {
            if solutions[i].len() < best_solution_length
            {
                best_solution = solutions[i].clone();
                best_solution_length = solutions[i].len();
            }
        }

        for i in 0..solutions.len()
        {
            if solutions[i].len() == best_solution_length
            {
                num_best_solutions += 1;
            }
        }

        println!("Number of best solutions {}", num_best_solutions);
        state.solution = best_solution.clone();

        if(num_best_solutions > state.config.max_best_solutions)
        {
            println!("Board forbidden => More than {} best solution(s)!", state.config.max_best_solutions);
            state.success = false;
            return;
        }

        state.success = true;
    }

    fn build_entity_struct(&self, state: &State, idx: EntityIndex) -> ExportEntity
    {
        return ExportEntity {
            kind: state.entities[idx].kind.clone(),
            knobs: state.entity_knobs[idx].get().clone(),
            rot: state.entities[idx].rot,
            bad: state.entities[idx].bad,
            auto: state.entities[idx].auto,
            support: state.entities[idx].support,
            number: state.entity_numbers[idx].count()
        };
    }

    fn get_level_as_json(&self, state: &mut State) -> ExportData
    {
        let mut cell_array = Vec::new();
        
        for cell in state.cells.iter()
        {
            let mut num : i8 = cell.kind as i8;
            if !cell.active { num = -1; }
            cell_array.push(num);
        }

        let mut knob_array = Vec::new();
        for i in 0..state.cells.len()
        {
            knob_array.push(state.cell_knob[i]);
        }

        let mut full_entity_array = Vec::new();
        for i in 0..state.cells.len()
        {
            let mut entity_array = Vec::new();
            if !state.cell_entity[i].is_none() 
            {
                let e_idx = state.cell_entity[i].unwrap();
                entity_array.push(self.build_entity_struct(state, e_idx));
            }

            if state.cells[i].player
            {
                entity_array.push(self.build_entity_struct(state, 0));
            }

            full_entity_array.push(entity_array);
        }

        let cfg : ExportConfig = ExportConfig {
            rev_wind: state.config.reverse_winding_up_allowed,
            man_act: state.config.player_activates_by_entering,
            act_repeat: state.config.activation_repeating_enabled,
            p_drag: state.config.player_dragging_enabled,
            drag_chain: state.config.allow_drag_chaining,
            team_stack: state.config.team_stack_enabled,
            stop_after_enc: state.config.stop_after_encounter
        };

        let export_data : ExportData = ExportData {
            width: state.config.width,
            height: state.config.height,
            cells: cell_array,
            cell_contents: knob_array,
            entities: full_entity_array,
            solution: state.solution.clone(),
            config: cfg
        };

        return export_data;
    }

    fn export_puzzle_to_json(state: &mut State, data: ExportData) 
    {
        let mut file_name = state.seed.clone();
        file_name.push_str(".json");

        let writer = BufWriter::new(File::create(file_name).unwrap());
        serde_json::to_writer_pretty(writer, &data).unwrap();
    }

    fn do_move(&self, state: &mut State, commands: &mut Commands, move_idx: usize)
    {
        commands.open_new_move();

        // move as far as we can
        loop
        {
            let move_command = Box::new(Move { idx: 0, dir: move_idx, drag: false, num: 1 });
            let res = commands.add_and_execute(state, move_command);

            if res.stop { break; }
        }

        // activate the thing we end on, if chaining is NOT allowed
        // (otherwise, it happens during the loop above, shouldn't do it here)
        let new_idx = state.entities[0].cell;
        if !state.cell_entity[new_idx].is_none()
        { 
            if state.config.player_activates_by_entering && !state.config.allow_drag_chaining
            {
                let activate_command = Box::new(Activate { idx: state.cell_entity[new_idx].unwrap(), o: false, o_dir: 0, o_num: 0, o_kind: "".to_string() });
                commands.add_and_execute(state, activate_command);
            }
        }

        // check for auto-movers (ignore player, so start from 1)
        for i in 1..state.entities.len()
        {
            //println!("{}", state.entities[i].auto);
            if !state.entities[i].auto { continue; }

            let activate_command = Box::new(Activate { idx: i, o: false, o_dir: 0, o_num: 0, o_kind: "".to_string() });
            commands.add_and_execute(state, activate_command);
        }

        if state.config.move_debug && state.success { println!("DO MOVE {}", move_idx); Debugger::print(state); }
        
    }

    fn undo_last_move(&self, state: &mut State, commands: &mut Commands)
    {
        commands.pop_and_rollback(state);
        
        if state.config.move_debug && state.success { println!("UNDO MOVE"); Debugger::print(state); }
    }

    fn max_states_exceeded(&self, state: &mut State, num_states: u32) -> bool
    {
        return num_states > state.config.max_states_allowed
    }

    // TO DO: All this type casting ... feels like I should use a comparator/match instead?
    fn point_heuristic_failed(&self, state: &mut State, cur_move: usize) -> bool
    {
        return state.entity_numbers[0].count() < ((cur_move as f32) * state.config.point_heuristic) as i8;
    }

    // TO DO: Update to count the number of bad entities
    fn in_win_state(&self, state: &mut State) -> bool
    {
        return state.bad_entities <= 0;
    }

    fn in_loss_state(&self, state: &mut State) -> bool
    {
        return state.entities[0].dead;
    }

    
}

struct MoveHelper {}

impl MoveHelper {
    fn is_valid_move(state: &State, entity: EntityIndex, move_idx: usize) -> bool
    {
        let start_cell = state.entities[entity].cell;
        let target_cell = GridHelper::get_cell_in_dir(state, start_cell, move_idx);
        if target_cell.is_none() { return false; }

        return MoveHelper::can_enter(state, entity, target_cell.unwrap());
    }

    fn can_enter(state: &State, entity: EntityIndex, cell: CellIndex) -> bool
    {
        if !state.cells[cell].active { return false; }
        if MoveHelper::entities_disallow_entry(state, cell, entity) { return false; }
        return true;
    }

    fn must_stop(state: &State, entity: EntityIndex, cell: CellIndex) -> bool
    {
        let is_player = entity == 0;

        if !is_player && MoveHelper::cell_is_hole(state, cell) { return true; }
        if state.cell_entity[cell].is_none() { return false; }

        let e_idx = state.cell_entity[cell].unwrap();
       
        // passthrough - positively wound? Don't have to stop
        if is_player && (state.entities[e_idx].kind == "passthrough" && state.entity_numbers[e_idx].count() > 0) { return false; }
        return true;
    }

    fn cell_is_hole(state: &State, cell: CellIndex) -> bool
    {
        return state.cells[cell].kind == 1 
    }

    fn entities_disallow_entry(state: &State, cell: CellIndex, entity: EntityIndex) -> bool
    {
        if state.cell_entity[cell].is_none() { return false; }
        
        let e_idx = state.cell_entity[cell].unwrap();
        let is_player = entity == 0;
        let same_team = state.entities[e_idx].bad == state.entities[entity].bad;

        // passthrough - negatively wound? we cannot even enter here!
        if is_player && (state.entities[e_idx].kind == "passthrough" && state.entity_numbers[e_idx].count() < 0) { return true; }
        if same_team && !is_player && !state.config.team_stack_enabled { return true; }

        return false;
    }

    fn rotate_knob_at(state: &mut State, commands: &mut Commands, cell: Option<CellIndex>, cw: i8, dir: usize)
    {
        if cell.is_none() { return; }

        let cell = cell.unwrap();
        if state.cell_entity[cell].is_none() { return; }

        let entity = state.cell_entity[cell].unwrap();

        let invert_dir = (dir + 2) % 4; // the dir we get is from outside in, we want from inside out, so the reverse
        let local_dir = (invert_dir + 4 - state.entities[entity].rot) % 4; // un-rotate the knob position to account for rotation

        if !state.entity_knobs[entity].has(local_dir) { return; }
        if state.entity_numbers[entity].at_max_capacity(state.config.total_points_max) { return; }

        state.entity_knobs[entity].turn(local_dir);

        commands.add_and_execute(state, Box::new(TurnKnob { e_idx: entity, change_dir: cw }));
    }
}

struct GridHelper {}

impl GridHelper {
    fn out_of_bounds(state: &State, x: i8, y: i8) -> bool
    {
        return x < 0 || y < 0 || x >= (state.config.width as i8) || y >= (state.config.height as i8)
    }

    fn get_cell_index(state: &State, x: i8, y: i8) -> Option<CellIndex>
    {
        if GridHelper::out_of_bounds(state, x,y) { return None; }
        return Some((x + y * (state.config.width as i8)) as usize);
    }

    fn get_cell_coords(state: &State, idx: CellIndex) -> (i8, i8)
    {
        let x = idx % state.config.width;
        let y = ((idx as f32) / (state.config.width as f32)).floor();
        return (x as i8, y as i8);
    }

    fn get_empty_cell(state: &State, rng: &mut Pcg64, is_player: bool) -> Option<CellIndex>
    {
        let mut empty_cells = Vec::new();
        for i in 0..state.cells.len()
        {
            if !state.cells[i].active { continue; }
            if !is_player && MoveHelper::cell_is_hole(state, i) { continue; }
            if !state.cell_entity[i].is_none() { continue; }
            empty_cells.push(i);
        }

        if empty_cells.len() <= 0 { return None; }

        let rand_cell_index : usize = *empty_cells.choose(rng).unwrap();
        return Some(rand_cell_index);
    }

    fn get_cell_in_dir(state: &State, start_cell: CellIndex, dir: usize) -> Option<CellIndex>
    {
        let pos = GridHelper::get_cell_coords(state, start_cell);
        let move_vec = state.config.move_dirs[dir];
        let new_index = GridHelper::get_cell_index(state, pos.0 + move_vec.0, pos.1 + move_vec.1);
        return new_index;
    }

    fn get_cell_in_dir_extended(state: &State, start_cell: CellIndex, dir: usize, num: i8) -> Option<CellIndex>
    {
        let mut coords = GridHelper::get_cell_coords(state, start_cell);
        let move_vec = state.config.move_dirs[dir];

        coords = (coords.0 + move_vec.0*num, coords.1 + move_vec.1*num);
        
        let new_index = GridHelper::get_cell_index(state, coords.0, coords.1);
        return new_index;
    }

    fn find_first_entity_in_dir(state: &State, start_cell: CellIndex, dir: usize) -> Option<EntityIndex>
    {
        let mut new_cell = start_cell;
        loop {
            let cur_cell = GridHelper::get_cell_in_dir(state, new_cell, dir);
            if cur_cell.is_none() { return None; }
            
            let cur_cell = cur_cell.unwrap();
            new_cell = cur_cell;
            if !state.cells[cur_cell].active { continue; }
            
            if state.cell_entity[cur_cell].is_none() { continue; }
            return Some(state.cell_entity[cur_cell].unwrap());
        }
    }

    fn get_dir_as_vec(dir: usize) -> (i8, i8)
    {
        if dir == 0 { return (1,0); }
        else if dir == 1 { return (0,1); }
        else if dir == 2 { return (-1,0); }
        return (0,-1);
    }

    fn get_vec_as_dir(x: i8, y: i8) -> usize
    {
        if x == 1 { return 0; }
        else if y == 1 { return 1; }
        else if x == -1 { return 2; }
        return 3;
    }

    fn knob_points_at_nothing(state: &State, cell_idx: CellIndex, rand_rot: usize, index: usize) -> bool
    {
        let coords = GridHelper::get_cell_coords(state, cell_idx);
        let knob_dir = GridHelper::get_dir_as_vec((rand_rot + index) % 4);
        let other_cell = (coords.0 + knob_dir.0, coords.1 + knob_dir.1);
        if GridHelper::out_of_bounds(state, other_cell.0, other_cell.1) { return true; }
        
        let other_cell_index = GridHelper::get_cell_index(state, other_cell.0, other_cell.1);
        if !state.cells[other_cell_index.unwrap()].active { return true; }
        return false;
    }
}

struct Debugger {}

impl Debugger {
    fn print(state: &State)
    {
        println!("");
        for y in 0..state.config.height
        {
            let mut upper_line = String::new();
            let mut middle_line = String::new();

            for x in 0..state.config.width
            {
                let index = GridHelper::get_cell_index(state, x as i8, y as i8).unwrap();

                upper_line.push_str("-------");
                middle_line.push_str("|");

                if state.cells[index].active
                {
                    if state.cells[index].player
                    {
                        middle_line.push_str("P   ");
                    }
                    else if !state.cell_entity[index].is_none()
                    {
                        let entity = state.cell_entity[index].unwrap();
                        if state.entities[entity].bad {
                            middle_line.push_str("B");
                        } else {
                            middle_line.push_str("G");
                        }

                        let number : i8 = state.entity_numbers[entity].count();
                        middle_line.push_str(&number.to_string());

                        let rot = state.entities[entity].rot;
                        middle_line.push_str("r");
                        middle_line.push_str(&rot.to_string());
                        
                    } else {
                        middle_line.push_str("    ");
                    }

                    

                } else {
                    middle_line.push_str("-   ");
                }

                middle_line.push_str(" |");
            }

            println!("{}", upper_line);
            println!("{}", middle_line);
        }
        println!("");
    }

    fn print_solution(&self, state: &mut State, simulator: Simulator)
    {
        let solution = state.solution.clone();
        let mut commands = Commands::new();
        let mut statistics = Statistics::new();

        if solution.len() < state.config.min_moves
        {
            if solution.len() > 0 { println!("Board forbidden => Solution length too low {}", solution.len()); }
            state.success = false;
            return;
        }

        println!("###")
        println!("Printing Solution");
        println!("###");

        state.reset_statistics();
        let export_data = simulator.get_level_as_json(state);

        statistics.check_solution(&solution);

        for i in 0..solution.len()
        {
            simulator.do_move(state, &mut commands, solution[i]);
            statistics.record(state);
            Debugger::print(state);
        }

        statistics.check_commands(&commands);
        statistics.check_state_stats(state);

        statistics.disallow_state_if_bad(state);

        if state.success {
            Simulator::export_puzzle_to_json(state, export_data);
        }

        println!("###")
        println!("End of Solution");
        println!("###");
    }
}

struct Statistics {
    max_windup_number: i8,
    uses_reverse: bool,
    has_shuffle: bool,
    has_circle: bool,
    cells_dragged: u8,
    cell_used_ratio: f32,
    entity_used_ratio: f32,
    num_unused_knobs: u8,
    num_used_knobs: u8,
    times_stacked: usize,
    num_support_used: usize,
    max_battery: usize,
}

impl Statistics {
    fn new() -> Self {
        Self {
            max_windup_number: 0,
            uses_reverse: false,
            has_shuffle: false,
            has_circle: false,
            cells_dragged: 0,
            cell_used_ratio: 0.0,
            entity_used_ratio: 0.0,
            num_unused_knobs: 0,
            num_used_knobs: 0,
            times_stacked: 0,
            num_support_used: 0,
            max_battery: 0
        }
    }

    // DEBUGGING: this is where I can add very specific checks to force puzzles in a certain direction
    fn disallow_state_if_bad(&self, state: &mut State)
    {
        println!("Used knobs {}", self.num_used_knobs);
        println!("Unused knobs {}", self.num_unused_knobs);

        /*
        if self.max_windup_number <= 1 { 
            println!("Board forbidden => windup number too low");
            state.success = false; 
        }

        if self.cells_dragged < 2 { 
            println!("Board forbidden => player not dragged enough");
            state.success = false; 
        }
        */
       
        if self.entity_used_ratio < state.config.entity_used_ratio { 
            println!("Board forbidden => too few entities actually used");
            state.success = false; 
        }

        if self.cell_used_ratio < state.config.cell_used_ratio { 
            println!("Board forbidden => too few cells actually used");
            state.success = false; 
        }

        if self.has_shuffle { 
            println!("Board forbidden => has shuffle in solution");
            state.success = false; 
        }

        if self.has_circle { 
            println!("Board forbidden => has circle in solution");
            state.success = false; 
        }

        /*
        if self.max_battery < 1 {
            println!("Board forbidden => no battery actually used");
            state.success = false;
        }
        */

        /*
        if self.num_support_used < 1 {
            println!("Board forbidden => too few support used");
            state.success = false;
        }

        */

        /*
        if self.times_stacked < 1 {
            println!("Board forbidden => stacking ability not used");
            state.success = false;
        }
        */

        /*
        if self.num_used_knobs < 3 {
            println!("Board forbidden => too few knobs actually used");
            state.success = false;
        }

        if self.num_unused_knobs > 2 { 
            println!("Board forbidden => too many unused knobs");
            state.success = false; 
        }
        */
    }

    fn check_solution(&mut self, sol: &Vec<usize>)
    {
        // what counts as a circle (4 = full circle, could be 3 or 5 if it doesn't work great)
        let min_circle_length = 4;
        for i in 2..sol.len()
        {
            let val = sol[i];
            if val == sol[i-2] && sol[i-1] == (val+2) % 4
            {
                self.has_shuffle = true;
                break;
            }
        }

        // check both clockwise and counter-clockwise circles
        let mut circle_length = 0;
        for i in 1..sol.len() {
            let val = sol[i];
            if val == (sol[i-1] + 1) % 4
            {
                circle_length += 1;
                if circle_length >= min_circle_length { self.has_circle = true; break; }
            } else {
                circle_length = 0;
            }
        }

        for i in 1..sol.len() {
            let val = sol[i];
            if val == (sol[i-1] + 4 - 1) % 4
            {
                circle_length += 1;
                if circle_length >= min_circle_length { self.has_circle = true; break; }
            } else {
                circle_length = 0;
            }
        }
    }

    fn check_commands(&mut self, commands: &Commands)
    {
        for cmd in commands.command_names.iter()
        {
            println!("Command {}", cmd);
            let is_drag_cmd = cmd == "PosChange";
            if is_drag_cmd {
                self.cells_dragged += 1;
            }
        }
    }

    fn check_state_stats(&mut self, state: &mut State)
    {
        // CELLS USED
        let mut num_total : f32 = state.cells_used.len() as f32;
        let mut num_used : f32 = num_total;
        
        for i in 0..state.cells_used.len()
        {
            if !state.cells[i].active { num_total -= 1.0; } 
            if !state.cells_used[i] { num_used -= 1.0; }
        }

        self.cell_used_ratio = num_used / num_total;

        // ENTITIES USED
        // NOTE: player is removed from total and used count, hence -1 and starting loop from 1
        let mut ent_total : f32 = (state.entities_used.len() as f32) - 1.0;
        let mut ent_used : f32 = ent_total;

        for i in 1..state.entities_used.len()
        {
            if state.entities[i].bad && state.config.dont_count_bad_in_used_entities { ent_used -= 1.0; ent_total -= 1.0; continue; }
            if !state.entities_used[i] { ent_used -= 1.0; }
        }

        self.entity_used_ratio = ent_used / ent_total;

        // KNOBS (UN)USED
        let mut knobs_unused : u8 = 0;
        let mut knobs_used : u8 = 0;
        for i in 1..state.entity_knobs.len()
        {
            knobs_unused += state.entity_knobs[i].count_unused();
            knobs_used += state.entity_knobs[i].count_used();
        }

        self.num_unused_knobs = knobs_unused;
        self.num_used_knobs = knobs_used;

        // STACK ABILITY USED
        self.times_stacked = state.times_stacked;

        // SUPPORT ABILITY USED
        self.num_support_used = state.num_support_used;
    }

    fn record(&mut self, state: &State)
    {
        for i in 0..state.entities.len()
        {
            let num = state.entity_numbers[i].count();
            if num < 0 { self.uses_reverse = true; }

            self.max_windup_number = self.max_windup_number.max(num.abs());
        }

        let cur_battery : usize = state.player_number.abs() as usize;
        self.max_battery = self.max_battery.max(cur_battery);
    }
}

fn main() {
    let config = SimulationConfig {
        move_debug: false,

        width: 5,
        height: 5,
        min_moves: 8,
        max_moves: 12,
        max_best_solutions: 3,

        move_dirs: vec![(1,0),(0,1),(-1,0),(0,-1)],

        max_move_options: 4,
        max_states_allowed: 5000000,

        point_heuristic: 0.0,

        cell_disable_prob: 0.1,
        knob_add_prob: 0.1, // 0.1-0.3 is fine?
        loose_knob_prob: 0.125,
        no_outward_knobs: true,

        reverse_winding_up_allowed: true,
        player_activates_by_entering: true,
        activation_repeating_enabled: true,
        player_dragging_enabled: true,
        team_stack_enabled: true,
        stop_after_encounter: false,

        allow_drag_chaining: true,
        forbid_knobs_on_bunnies: false,
        bunnies_only_move: false,
        dont_count_bad_in_used_entities: true,

        // cell types we're allowed to choose from (there aren't many, they're mostly to teach the game)
        // NOTE: CRUCIAL, don't add holes when we have wizards, the simulation never finds anything useful
        cell_types: vec![0],

        // entity types we're allowed to choose from
        // vec!["move", "attract", "repel",  "jump", "rotate"]
        entity_types: vec!["move", "attract", "repel", "jump", "rotate", "convert", "destruct", "passthrough", "battery"].into_iter().map(|s| s.to_owned()).collect(),
        required_entity_types: vec![], //vec!["battery"].into_iter().map(|s| s.to_owned()).collect(),

        // range for number of entities:
        entity_num: (5,6),

        // probability of adding a bad wizard ( = energy exterminator)
        bad_prob: 0.4, // 0.3 seems fit for regular levels with good wizards
        bad_min: 1,

        // minimum good wizards (their probability is just 1.0 - bad_prob)
        good_min: 1,

        // probability of making something a support wizard + minimum required
        // usually 0.0 and 0, support only occurs on specific wizards
        // but can be used to sprinkle random support in here and there
        support_prob: 0.3, 
        support_min: 1,

        // probability of making something an auto wizard + minimum required
        auto_prob: 0.0,
        auto_min: 0,

        entity_starting_points_max: 1,
        total_points_max: 4,
        player_can_have_points: false,

        // requirements on solution to be "valid"
        // for larger maps: 0.45, 0.7
        cell_used_ratio: 0.45, //0.66
        entity_used_ratio: 1.0
    };

    loop {
        let mut state = State::new(config.clone());
        let mut generator = Generator {};
        let simulator = Simulator { };
        let debugger = Debugger {};

        generator.create_board(&mut state);
        Debugger::print(&state);

        simulator.try_all_moves(&mut state);

        let stop_after_one_success = false; //state.success;

        Debugger::print(&state); // should be identical to the previous print, otherwise something went wrong

        debugger.print_solution(&mut state, simulator);

        if stop_after_one_success { break; }

        if state.success { break; }
    }

    println!("Generation done");
}