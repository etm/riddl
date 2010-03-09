#!/usr/bin/ruby

require '../../lib/ruby/client'
require 'rubygems'
require 'xml/smart'


client = Riddl::Client.new("http://localhost:9290")

if ARGV[0] == nil
  puts "No workflow-file given"
  exit
end

# Define namespaces
flow = 'http://rescue.org/ns/controlflow/0.2'

# Open workflow
puts "Open file #{ARGV[0]}"
workflow = XML::Smart.open(ARGV[0])
# Get class-level-workflow for each call
workflow.find("/flow:controlflow/flow:call[string(@service-operation)]", {"flow" => flow}).each do |call|
  endpoint = workflow.find("//flow:endpoint[@id = '#{call.attributes.get_attr("endpoint")}']", {"flow"=> flow}).first.text
  service_operation= call.attributes.get_attr("service-operation")
  state_controlflow = call.attributes.get_attr("state-controlflow")
  puts state_controlflow
  puts "Requesting service-operation #{service_operation}: groups/#{endpoint.split("/")[0]}/operations/#{service_operation}"
  status, response = client.resource("groups/#{endpoint.split("/")[0]}/operations/#{service_operation}").get
  puts "Error receiving information from: groups/#{endpoint.split("/")[0]}/operations/#{service_operation}" if status != 200
  class_workflow = XML::Smart.string(response[0].value.read)
  puts class_workflow.find("//flow:#{state_controlflow}", {"flow"=> flow}).first
  call.add_after(class_workflow.find("//flow:#{state_controlflow}", {"flow"=> flow}).first)
end
# Get service-worflows
# Print final workflow
puts workflow
