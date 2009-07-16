# Responds a list of all avaliable groups as an ATOM feed
class GroupsGET < Riddl::Implementation
  include MarkUSModule

  $url = 'http://localhost:9292/'
  
  def response
    groups = []
    Dir["repository/#{@r[0]}/*"].each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end  

    Riddl::Parameter::Complex.new("list-of-groups","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
        title_ 'List of groups'
        updated_ File.mtime("repository/#{@r[0]}").xmlschema
        generator_ 'My Repository at local host'
        id_ "#{$url}#{@r[0]}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}#{@r[0]}/"
        groups.each do |g|
          entry_ do
            id_ "#{$url}#{@r[0]}/#{g}/"
            link_ "#{$url}#{@r[0]}/#{g}/"
            updated_ File.mtime("repository/#{@r[0]}/#{g}").xmlschema
          end
        end  
      end
    end  
  end
end

# Creates a new Group in the repository
class GroupPOST < Riddl::Implementation
  def response
    begin
      puts "Generating group named '#{@p[0].value}' ...."
      Dir.mkdir("repository/groups/#{@p[0].value}")
      @staus = 200
      puts 'OK (200)'
    rescue
      @status = 409 # http ERROR named 'Conflict'
      puts $ERROR_INFO
    end
  end
end

# PUT updates the RIDDL description of the group
class GroupPUT < Riddl::Implementation
  def response
      @staus = 501 # HTTP-Error 'Not supported' ... must be to update the description of the group
  end
end

# DELETE deltes a group and subgroups and services included
class GroupDELETE < Riddl::Implementation
  def response
    begin
      puts "Deleting group named '#{@p[0].value}' ...."
      FileUtils.rm_rf 'repository/groups/#{@p[0].value}'
      # Dir.mkdir("repository/groups/#{@p[0].value}")
      @staus = 200
      puts 'OK (200)'
    rescue
      @status = 404 # http ERROR named 'Not found'
      puts $ERROR_INFO
    end
  end
end


# Rsepond is the XML-Schema of the supported messegas of the group
class GroupRIDDL < Riddl::Implementation
  def response
    begin
      puts "RIDDL description of group '#{@p[0].value}' ...."
      ret = Riddl::Parameter::Complex.new("list-of-services","text/xml") do
        File.open("repository/#{@r[0]}.xml")
      end
      @staus = 200
      puts 'OK (200)'
      return ret
    rescue
      @status = 404 # http ERROR named 'REsource not found'
      puts $ERROR_INFO
    end
  end
end

