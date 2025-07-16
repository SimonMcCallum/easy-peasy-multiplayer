extends Control

@export var dark_path: String = "res://assets/slides/dark"
@export var light_path: String = "res://assets/slides/light"

@onready var slide_rect: TextureRect = %SlideRect
var slides: Array[Texture2D] = []
var current := 0

func _ready() -> void:
        var folder := dark_path if multiplayer.get_unique_id() == 1 else light_path
        var dir := DirAccess.open(folder)
        if dir:
                dir.list_dir_begin()
                var file := dir.get_next()
                while file != "":
                        if not dir.current_is_dir() and file.ends_with(".png"):
                                slides.append(load(folder + "/" + file))
                        file = dir.get_next()
                dir.list_dir_end()
        slides.sort_custom(func(a, b): return a.resource_path < b.resource_path)
        if slides.size() > 0:
                slide_rect.texture = slides[0]

func _input(event: InputEvent) -> void:
        if event.is_action_pressed("ui_accept") and slides.size() > 0:
                current = (current + 1) % slides.size()
                slide_rect.texture = slides[current]