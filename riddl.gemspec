Gem::Specification.new do |s|
  s.name             = "riddl"
  s.version          = "0.99.5"
  s.platform         = Gem::Platform::RUBY
  s.summary          = "restful interface description and declaration language: tools and client/server libs"

  s.description = <<-EOF
Write useful stuff.

Also see http://www.pri.univie.ac.at/communities/riddl/.
EOF

  s.files            = Dir['{lib/riddl/ns/**/*,tools/**/*,ns/**/*,contrib/**/*,lib/riddl/**/*,example/**/*}'] + %w(COPYING Rakefile riddl.gemspec README AUTHORS INSTALL)
  s.require_path     = 'lib'
  s.has_rdoc         = false
  s.extra_rdoc_files = ['README']
  s.bindir           = 'tools'
  s.executables      = ['riddlcheck','riddlprocess']


  s.authors          = ['Juergen eTM Mangler']
  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://www.pri.univie.ac.at/communities/riddl/'

  s.add_development_dependency 'riddl-xml-smart'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'mongrel'
  s.add_development_dependency 'mime-types'
  s.add_development_dependency 'activesupport'
  s.add_development_dependency 'i18n'
end
