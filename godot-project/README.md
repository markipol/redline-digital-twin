# Godot Project - Digital Twin

This folder contains the main Godot Engine project for the Digital Innovation Hub - Digital Twin.

## Structure of Godot project

- **addons/**: Godot add-ons
- **models/**: 3D models in GLB format (imported into the project).
- **scenes/**: Godot scene files for the building, UI, and other elements.
- **scripts/**: GDScript files for logic and interactivity.
- **resources/**: Miscellaneous godot .tres resources (button groups).
- **textures/**: texture files for the UI.

## Opening the project in Godot

To get started simply open this folder's project.godot in Godot 4.4, the addons are already included in the project

## Development Notes

- Place exported GLB files in `models/` (see [Modelling assets/_GLBs_go_in_godot_project_models_folder.txt](../Modelling%20assets/_GLBs_go_in_godot_project_models_folder.txt)).
- UI elements for floor selection are in `scenes/main.tscn`.

## Dependencies

- Godot 4.4
- Add-ons (included in project, no need to download or install):
  - Debug menu (press f3 for FPS and other performance stats)
  - Plugin manager, easily turn on and off plugins from the top right
  - Virtual joystick, for mobile control or control without a keyboard or captured mouse, in a mobile FPS fashion

