extends Node
# Autoload name: TestBridge — Web-export-only JS hooks for Playwright (HLD 4.13).
# Active only in builds exported with the "test_bridge" custom feature tag, so the
# hooks never ship in a normal build (HLD-R-008). Implemented in LLD-test-bridge.md.


func _ready() -> void:
	if not (OS.has_feature("web") and OS.has_feature("test_bridge")):
		return
	# mythcards_get_state() / mythcards_dispatch_action() are registered here in a later step.
