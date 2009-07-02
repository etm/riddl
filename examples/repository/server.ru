require 'rack'
require 'socket'
require '../../lib/ruby/server'
require 'MarkUS_V3.0'
require 'xml/smart'


require 'mysql'

use Rack::ShowStatus



class Root < Riddl::Implementation
  include MarkUS

  def response
    # puts "Processing request on root resource (List of groups)"
    #m = Mysql.new('localhost', 'root', 'thesis')
    #m.select_db('thesis')
    #result = m.query("SELECT * FROM SERVICE_GROUP")

    Dir['repository'].each do |f|
      if f.directory?
      feed = feed_ do 
        title_ "list of groups"
        updated_ ""
        link_ :href => 'http://bla' do 
          text_! test
        end
        XML::Smart.open("test.xml
      end  

    #feed = <<-HERE_DOC
      <feed>
        <title>List of groups</title>
        <updated>No date at the monent</updated>
        <generator>My Repositorxy at local host</generator>
        <id>localhost/</id>
        <link href="localhost" rel="self" type="application/atom+xml"/>
        <schema>
          <properties>URI to properties</properties>
          <queryInput>N.A.</queryInput>
          <queryOutput>N.A.</queryOutput>
          <invokeInput>N.A.</invokeInput>
          <invokeOutput>N.A.</invokeOutput>
        </schema>
HERE_DOC

    results.each do |row|
      feed = feed + "  <entry lang="">\”"
      feed = feed + "    <id>" + row['ID'] + "</id>\n"
      feed = feed + "    <link>localhost/" + row['NAME'] + "</link>\n"
      feed = feed + "    <updated>N.A.</updated>\n"
      feed = feed + "    <category term="/"/>\n"
      feed = feed + "    <properties>N.A.</properties>\n"
      feed = feed + "  </entry>\n"
    end
    feed = feed + "</feed>\n"
 
    Riddl::Parameter::Complex.new("list-of-groups","text/xml", feed)
  end

  def status
    200
  end
end


class Category < Riddl::Implementation
  def response
    p @r.last                                        # e.g. cinemas for /cinemas
  end
end

class SubCategory < Riddl::Implementation
  def response
    p @r.last                                        # e.g. arthouse for /cinemas/arthouse
  end
end

class Item < Riddl::Implementation
  def response
    p @r.last                                        # e.g. 1 for /cinemas/arthouse/1
    p @r[0]                                          # e.g. cinemas
    p @r[1]                                          # e.g. arthouse
  end
end

run(
  Riddl::Server.new("description.xml") do
    process_out true
    on resource do                                    # "/"
      run Root if get '*'
      on resource do                                  # "/cinemas"
        run Category if get '*'
        on resource do "/cinemas/arthouse"
          run SubCatgory if get '*'
          on resource do "/cinemas/arthouse/1"
            run Item if get '*'
          end
        end
      end
    end
  end
)

