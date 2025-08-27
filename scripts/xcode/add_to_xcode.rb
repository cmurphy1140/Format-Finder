#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/connormurphy/Desktop/Format Finder/FormatFinder.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group (FormatFinder folder)
main_group = project.main_group['FormatFinder']

# Files to add
files_to_add = [
  'GameModeSelector.swift',
  'ScorecardContainer.swift',
  'FormatScorecards.swift',
  'AdvancedScorecards.swift',
  'RemainingFormatScorecards.swift',
  'StatsAndExport.swift'
]

# Get the target
target = project.targets.first

files_to_add.each do |filename|
  file_path = "/Users/connormurphy/Desktop/Format Finder/FormatFinder/#{filename}"
  
  # Check if file already exists in project
  existing_file = main_group.files.find { |f| f.path&.include?(filename) }
  
  if existing_file.nil? && File.exist?(file_path)
    # Add file reference to the project
    file_ref = main_group.new_file(file_path)
    
    # Add the file to the target's build phase
    target.source_build_phase.add_file_reference(file_ref)
    
    puts "Added #{filename} to project"
  elsif existing_file
    puts "#{filename} already in project"
  else
    puts "#{filename} not found at #{file_path}"
  end
end

# Save the project
project.save
puts "\nProject updated successfully!"