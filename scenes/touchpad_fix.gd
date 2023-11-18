# Public domain, as per The Unlicense. NO WARRANTY. See https://unlicense.org

extends Node
## Solves a [url=https://github.com/godotengine/godot/issues/59250]bug[/url] where touchpad devices
## can be detected as a joypad.
##
## This script should be autoloaded in the project settings.
## This is merely a workaround, not for use in production code.

func _ready() -> void:
	int(Input.joy_connection_changed.connect(Callable(get_script(), joy_check.get_method())))
	queue_free()

## Validates a joypad connection. Called for every joypad device connected.
## Device names matching the pattern will be disabled (remapped to an empty mapping).
static func joy_check(device_id: int, connected: bool) -> void:
	if not connected:
		return
	var device_name := Input.get_joy_name(device_id)
	# Uncomment the line below to debug problematic devices:
	# print('Connected device ', device_id, ': ', device_name)
	if not is_banned(device_name):
		return
	# Device should be ignored.
	var guid := Input.get_joy_guid(device_id)
	var mapping := guid + ',' + device_name.replace(',', '') # not mapping any axes or buttons
	# Replace with empty mapping on this guid. Should ignore all joypad input from this device.
	Input.add_joy_mapping(mapping, true)
	prints('Ignoring joypad device:', mapping) # you can comment out or remove this line

## True only if the device name contains a banned word, case-insensitively.
## A banned substring only matches if it's guaranteed to be a separate word.
static func is_banned(device_name: String) -> bool:
	for word in banned_words:
		var i := device_name.findn(word)
		if i < 0:
			continue # this banned word was not found as a substring
		if i > 0 and not is_ascii_non_letter(device_name[i - 1]):
			continue # substring found, but it's not guaranteed to start a word
		var j := i + word.length()
		if j < device_name.length() and not is_ascii_non_letter(device_name[j]):
			continue # it starts a word, but it's not guaranteed to also end it
		return true # substring found and guaranteed to form a separate word
	return false # no banned word found

## True only if the character is ASCII and not a letter.
static func is_ascii_non_letter(c: String) -> bool:
	return c.unicode_at(0) < 128 and not (c >= 'a' and c <= 'z' or c >= 'A' and c <= 'Z')

## List of words forbidden in joypad names.
static var banned_words: PackedStringArray = [
	'touchpad', 'trackpad', 'clickpad',
	'mouse',
	'pen',
]
