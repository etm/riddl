Gem::Specification.new do |s|
  s.name             = "riddl"
  s.version          = "1.0.6"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3.0-or-later"
  s.summary          = "Restful Interface Description and Declaration Language: tools and client/server libs"

  s.description      = "REST service interface definition, mixing, and evolution. Supports mixed http and xmpp servers."

  s.files            = Dir['{lib/ruby/riddl/ns/**/*,tools/**/*,ns/**/*,contrib/**/*,lib/ruby/riddl/**/*,examples/**/*}'] + %w(COPYING Rakefile riddl.gemspec README.md TODO AUTHORS INSTALL.md)

  s.require_path     = 'lib/ruby'
  s.extra_rdoc_files = ['README.md']
  s.bindir           = 'tools'
  s.executables      = ['riddlcheck','riddlprocess']
  s.test_files       = Dir['test/tc_*.rb','test/smartrunner.rb']

  s.email            = 'juergen.mangler@gmail.com'
  s.authors          = ['Juergen \'eTM\' Mangler','Florian \'Solo\' Stertz','Sonja Biedermann','Matthias Ehrendorfer']
  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://github.com/etm/riddl/'

  s.required_ruby_version = '>=2.2.0'

  s.add_runtime_dependency 'daemonite', '~>0.7', '>=0.7.0'
  s.add_runtime_dependency 'typhoeus', '~>1.3'
  s.add_runtime_dependency 'xml-smart', '>=0.4.3', '~>0'
  s.add_development_dependency 'rdf-smart', '>=0.0.160', '~>0'
  s.add_runtime_dependency 'rack', '~>2.2'
  s.add_runtime_dependency 'thin', '~>1.6'
  s.add_runtime_dependency 'eventmachine', '>= 1.0.0', '~>1.0'
  s.add_runtime_dependency 'em-websocket', '>= 0.5.2', '~>0'
  s.add_runtime_dependency 'faye-websocket', '>= 0.1', '~>0'
  s.add_runtime_dependency 'mime-types', '>= 3.0', '~>3'
  s.add_runtime_dependency 'minitest', '>= 5.0.0', '~>5'
  s.add_runtime_dependency 'charlock_holmes', '>= 0.7', '~>0'
  s.add_runtime_dependency 'redis', '~> 5.0'
end
