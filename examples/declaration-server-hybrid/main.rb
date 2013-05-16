#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/riddl/utils/fileserve')

class Info < Riddl::Implementation
  def response
    unless File.exists?("instances/#{@r[0]}")
      @status = 400
      return
    end
    Riddl::Parameter::Complex.new("info","text/xml") do
      i = XML::Smart::string <<-END
        <?xml-stylesheet href="../xsls/info.xsl" type="text/xsl"?>
        <info instance='#{@r[0]}'>
          <properties/>
        </info>
      END
      i.to_s
    end
  end
end

Riddl::Server.new('main.xml', :port => 9296) do
  on resource do
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
end.loop!
