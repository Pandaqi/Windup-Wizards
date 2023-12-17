extends Node

var list = []

onready var map = get_node("/root/Main/Map")

func add(e):
	list.append(e)

func remove(e):
	list.erase(e)

func has_some():
	return list.size() > 0

func has_some_excluding(exclude = []):
	if exclude.size() <= 0: return has_some()
	return get_excluding(exclude).size() > 0

func has_specific(entity):
	return list.has(entity)

func player_is_here():
	return has_specific(map.get_player())

func allow_entry_to(other_entity):
	for e in list:
		if not e.executor.is_entry_allowed(other_entity): return false
	return true

func get_them():
	return list

func get_excluding(exclude = []):
	if exclude.size() <= 0: return get_them()
	
	var list_copy = list + []
	for e in exclude:
		list_copy.erase(e)
	return list_copy

func has_bad():
	for e in list:
		if e.is_player(): continue
		if e.bad: return true
	return false

func has_good():
	for e in list:
		if e.is_player(): continue
		if not e.bad: return true
	return false

func get_eater(node_being_eaten):
	for e in list:
		if e.is_player(): continue
		if e == node_being_eaten: continue
		if e.bad == node_being_eaten.bad: continue
		return e
	return null

func get_eat_victim(node_eater):
	for e in list:
		if e.is_player() or e == node_eater: continue
		if e.bad == node_eater.bad: continue
		return e
	return null

func same_team(node):
	for e in list:
		if e.is_player() or e == node: continue
		if e.bad == node.bad: return true
	return false
