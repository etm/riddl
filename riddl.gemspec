Gem::Specification.new do |s|
  s.name             = "riddl"
  s.version          = "0.99.188"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3"
  s.summary          = "restful interface description and declaration language: tools and client/server libs"

  s.description      = "rest service interface definition, mixing, and evolution. supports mixed http and xmpp servers."

  s.files            = Dir['{lib/ruby/riddl/ns/**/*,tools/**/*,ns/**/*,contrib/**/*,lib/ruby/riddl/**/*,examples/**/*}'] + %w(COPYING Rakefile riddl.gemspec README.rdoc TODO AUTHORS INSTALL)

  s.require_path     = 'lib/ruby'
  s.extra_rdoc_files = ['README.rdoc']
  s.bindir           = 'tools'
  s.executables      = ['riddlcheck','riddlprocess']
  s.test_files       = Dir['test/tc_*.rb','test/smartrunner.rb']


  s.authors          = ['Juergen eTM Mangler']
  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://www.wst.univie.ac.at/communities/riddl/'

  s.required_ruby_version = '>=1.9.3'

  s.add_runtime_dependency 'xml-smart', '>=0.3.6', '~>0'
  s.add_runtime_dependency 'rdf-smart', '>=0.0.160', '~>0'
  s.add_runtime_dependency 'rack', '~>1.6'
  s.add_runtime_dependency 'thin', '~>1.6'
  s.add_runtime_dependency 'eventmachine', '>= 1.0.0', '~>1.0'
  s.add_runtime_dependency 'em-websocket', '>= 0.4.0', '~>0'
  s.add_runtime_dependency 'em-websocket-client', '>= 0.1', '~>0'
  s.add_runtime_dependency 'mime-types', '>= 2.4', '~>2'
  s.add_runtime_dependency 'minitest', '>= 5.0.0', '~>5'
  s.add_runtime_dependency 'blather', '~>1'
  s.add_runtime_dependency 'charlock_holmes', '>= 0.7', '~>0'
end
