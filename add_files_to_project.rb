#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

# Open the project
project_path = 'FormatFinder.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files to add
files_to_add = [
  'FormatFinder/Core/Services/BackendServices.swift',
  'FormatFinder/Data/GolfFormatsData.swift',
  'FormatFinder/Features/Configuration/GameConfigurationView.swift',
  'FormatFinder/Features/Scorecards/EnhancedScorecardView.swift'
]

# Get the main group
main_group = project.main_group['FormatFinder']

# Function to create groups for path
def ensure_group_path(parent_group, path_components)
  current_group = parent_group
  path_components.each do |component|
    existing_group = current_group[component]
    if existing_group.nil?
      current_group = current_group.new_group(component)
    else
      current_group = existing_group
    end
  end
  current_group
end

# Get the main target
target = project.targets.first

# Track what we've added
added_files = []

files_to_add.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)
  
  if File.exist?(full_path)
    # Parse the path to determine group structure
    path = Pathname.new(file_path)
    path_parts = path.dirname.to_s.split('/')[1..-1]  # Remove 'FormatFinder' from beginning
    file_name = path.basename.to_s
    
    # Ensure the group structure exists
    target_group = ensure_group_path(main_group, path_parts)
    
    # Check if file already exists in project
    existing_ref = target_group.files.find { |f| f.path == file_name || f.path&.end_with?(file_name) }
    
    if existing_ref.nil?
      # Add the file reference
      file_ref = target_group.new_reference(full_path)
      
      # Add to target's build phases
      target.add_file_references([file_ref])
      
      added_files << file_path
      puts "Added: #{file_path}"
    else
      puts "Already exists: #{file_path}"
    end
  else
    puts "File not found: #{file_path}"
  end
end

# Save the project
project.save

puts "\nProject updated successfully!"
puts "Added #{added_files.length} files to the project."