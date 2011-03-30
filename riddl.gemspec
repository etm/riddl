Gem::Specification.new do |s|
  s.name             = "riddl"
  s.version          = "0.99.0"
  s.platform         = Gem::Platform::RUBY
  s.summary          = "restful interface description and declaration language: tools and client/server libs"

  s.description = <<-EOF
Write useful stuff.

Also see http://www.pri.univie.ac.at/communities/riddl/.
EOF

  s.files            = Dir['{lib/ruby/*,example/*}'] + %w(COPYING Rakefile riddl.gemspec README AUTHORS INSTALL)
  s.require_path     = 'lib/ruby'
  s.has_rdoc         = false
  s.extra_rdoc_files = ['README']

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
