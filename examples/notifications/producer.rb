#!/usr/bin/ruby
require '../../lib/ruby/server'
require '../../lib/ruby/utils/fileserve'
require '../../lib/ruby/utils/notifications_producer'

Riddl::Server.new(::File.dirname(__FILE__) + '/producer.declaration.xml', :port => 9291) do
  accessible_description true
  ndir = ::File.dirname(__FILE__) + '/notifications/'

  interface 'fluff' do
    run Riddl::Utils::FileServe, "implementation/index.html" if get
    on resource 'oliver' do
      run Riddl::Utils::FileServe, "implementation/oliver.html" if get
    end  
    on resource 'juergen' do
      run Riddl::Utils::FileServe, "implementation/juergen.html" if get
    end
  end

  interface 'main' do |r|
    use Riddl::Utils::Notifications::Producer::implementation(ndir)
  end  
end.loop!
