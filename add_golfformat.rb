#!/usr/bin/env ruby
require 'xcodeproj'

# Open the project
project_path = 'FormatFinder.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group
main_group = project.main_group['FormatFinder']

# Create or get Models group
models_group = main_group['Models'] || main_group.new_group('Models')
models_group.set_source_tree('<group>')
models_group.set_path('Models')

# Add GolfFormat.swift
file_ref = models_group.new_reference('GolfFormat.swift')
file_ref.set_source_tree('<group>')
file_ref.set_path('GolfFormat.swift')

# Add to build phase
target = project.targets.first
build_phase = target.source_build_phase
unless build_phase.files_references.include?(file_ref)
  build_phase.add_file_reference(file_ref)
end

# Save the project
project.save

puts "Successfully added GolfFormat.swift to the project"
