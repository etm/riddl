#!/usr/bin/ruby

require '../../lib/ruby/client'
require 'rubygems'
require 'xml/smart'
require 'lib/Workflow.rb'


client = Riddl::Client.new("http://localhost:9290")

if ARGV[0] == nil
  puts "No workflow-file given"
  exit
end

# Define namespaces
flow = 'http://rescue.org/ns/controlflow/0.2'

# Open workflow
puts "Open file #{ARGV[0]}"
workflow = Workflow.new(ARGV[0])

workflow.resolve_calls()

# Get service-worflows
# Print final workflow
puts workflow
