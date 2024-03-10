@tool
extends Node

@export
var neighbors: Array[String] = []
@export
var show_neighbors: bool = false:
    set(value):
        if value != show_neighbors:
            show_neighbors = value
            _update_neighbors()

func _ready() -> void:
    if show_neighbors:
        _update_neighbors()

func _update_neighbors() -> void:
    if not Engine.is_editor_hint(): return
    if not is_node_ready() or self != get_tree().edited_scene_root:
        return
    for c in get_children():
        if c.owner == null:
            remove_child(c)
            c.queue_free()
    if show_neighbors:
        for path in neighbors:
            if path.is_empty(): continue
            var n = load(path) as PackedScene
            if n and n.can_instantiate():
                var neighbor = n.instantiate()
                if neighbor:
                    add_child(neighbor)
                    move_child(neighbor, 0)
