#!/usr/bin/env ruby
require 'xcodeproj'

# Open the project
project_path = 'FormatFinder.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group
main_group = project.main_group['FormatFinder']
ui_group = main_group['UI']
theme_group = ui_group['Theme']

# Add MastersTheme.swift if not already present
masters_theme_ref = theme_group.files.find { |f| f.path == 'MastersTheme.swift' }
unless masters_theme_ref
  masters_theme_ref = theme_group.new_reference('MastersTheme.swift')
  masters_theme_ref.set_source_tree('<group>')
  
  # Add to build phase
  target = project.targets.first
  build_phase = target.source_build_phase
  build_phase.add_file_reference(masters_theme_ref)
  
  puts "Added MastersTheme.swift to the project"
else
  puts "MastersTheme.swift already in project"
end

# Save the project
project.save
