#!/usr/bin/ruby
require '../../lib/ruby/riddl/client'

client = Riddl::Client.new('http://cpee.org')
puts client.simulate_put([
  Riddl::Parameter::Simple::new('type','a'),
  Riddl::Parameter::Simple::new('topic','b'),
  Riddl::Parameter::Simple::new('event','c'),
  Riddl::Parameter::Complex::new('notification','application/json',"15")
]).read
