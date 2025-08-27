#!/usr/bin/env ruby
require 'xcodeproj'

# Open the project
project_path = 'FormatFinder.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Remove old reference
project.files.select { |f| f.path&.include?('GolfFormat.swift') }.each do |file|
  file.remove_from_project
end

# Get the main group
main_group = project.main_group['FormatFinder']

# Create or get Models group
models_group = main_group['Models'] || main_group.new_group('Models')
models_group.set_source_tree('<group>')

# Add GolfFormat.swift with correct path
file_ref = models_group.new_reference('GolfFormat.swift')
file_ref.set_source_tree('<group>')

# Add to build phase
target = project.targets.first
build_phase = target.source_build_phase
build_phase.add_file_reference(file_ref)

# Save the project
project.save

puts "Fixed GolfFormat.swift path in the project"
