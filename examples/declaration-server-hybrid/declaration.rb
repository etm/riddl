#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/fileserve')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/properties')

class Info < Riddl::Implementation
  def response
    unless File.exist?("instances/#{@r[0]}")
      @status = 400
      return
    end
    Riddl::Parameter::Complex.new("info","text/xml") do
      i = XML::Smart::string <<-END
        <info instance='#{@r[0]}'>
          <properties/>
        </info>
      END
      i.to_s
    end
  end
end

Riddl::Server.new(File.dirname(__FILE__) + '/declaration.xml', :port => 9002) do
  accessible_description true

  interface 'main' do
    run Riddl::Utils::FileServe, 'instances/instances.xml' if get '*'
    on resource do
      run Info if get
    end
    on resource 'xsls' do
      on resource do
        run Riddl::Utils::FileServe, "xsls"  if get
      end
    end
  end

  interface 'properties' do |r|
    properties = @riddl_opts[:basepath] + '/instances/' + r[:h]['RIDDL_DECLARATION_PATH'].split('/')[1] + '/properties.xml'
    backend = Riddl::Utils::Properties::Backend.new(
      @riddl_opts[:basepath] + '/instances/properties.schema',
      properties
    )

    use Riddl::Utils::Properties::implementation(backend)
  end
end.loop!
