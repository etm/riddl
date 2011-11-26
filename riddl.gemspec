Gem::Specification.new do |s|
  s.name             = "riddl"
  s.version          = "0.99.17"
  s.platform         = Gem::Platform::RUBY
  s.summary          = "restful interface description and declaration language: tools and client/server libs"

  s.description = <<-EOF
Write useful stuff.

Also see http://www.pri.univie.ac.at/communities/riddl/.
EOF

  s.files            = Dir['{lib/riddl/ns/**/*,tools/**/*,ns/**/*,contrib/**/*,lib/riddl/**/*,example/**/*}'] + %w(COPYING Rakefile riddl.gemspec README AUTHORS INSTALL)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README']
  s.bindir           = 'tools'
  s.executables      = ['riddlcheck','riddlprocess']


  s.authors          = ['Juergen eTM Mangler']
  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://www.pri.univie.ac.at/communities/riddl/'

  s.add_runtime_dependency 'ruby-xml-smart'
  s.add_runtime_dependency 'rack'
  s.add_runtime_dependency 'mongrel'
  s.add_runtime_dependency 'mime-types'
  s.add_runtime_dependency 'bindata'
end