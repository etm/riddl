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
        generator_ 'My Repository at local host', :uri => "#{$url}"
        id_ "#{$url}#{@r[0]}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}#{@r[0]}/"
        groups.each do |g|
          entry_ :lang => 'EN' do
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
      xmlString = @p[1].value.read
      x = XML::Smart.string(xmlString)
      if x.validate_against(XML::Smart::open("rngs/details-of-group.rng"))
        FileUtils.mkdir "repository/#{@r[0]}/#{@p[0].value}"
        detailsFile = File.new("repository/#{@r[0]}/#{@p[0].value}/details.xml", "w")
        detailsFile.write(xmlString)
        detailsFile.close()
        @status = 201  # 201: Created
       else 
        @status = 415 # 415: Unsupported Media Type
        puts "XML doesn't match the RNG schema (details-of-group.rng)"
      end 
   rescue
      @status = 409 # http ERROR named 'Conflict'
      puts $ERROR_INFO
    end
  end
end

# PUT updates the RIDDL description of the group
class GroupPUT < Riddl::Implementation
  def response
    if File.exist?("repository/#{@r[0]}/#{@r[1]}") == false
      puts "Updating group failed becaus group does not exist"
      @status = 410 # 410: Gone
      return
    end
    begin
      xmlString = @p[1].value.read
      x = XML::Smart.string(xmlString)
      if x.validate_against(XML::Smart::open("rngs/details-of-group.rng"))
        File.rename("repository/#{@r[0]}/#{@r[1]}","repository/#{@r[0]}/#{@p[0].value}")
        detailsFile = File.new("repository/#{@r[0]}/#{@p[0].value}/details.xml", "w")
        detailsFile.write(xmlString)
        detailsFile.close()
        @staus = 201  # 201: Created
      else 
        @status = 415 # 415: Unsupported Media Type
        puts "XML doesn't match the RNG schema (details-of-group.rng)"
      end 
    rescue
      @status = 409 # http ERROR named 'Conflict'
      puts $ERROR_INFO
    end
  end
end

# DELETE deltes a group and subgroups and services included
class GroupDELETE < Riddl::Implementation
  def response
    begin
      puts "Deleting group named '#{@r[1]}' ...."
      FileUtils.rm_r "repository/#{@r[0]}/#{@r[1]}"
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
        File.open("repository/#{@r[0]}/detauíls.xml")
      end
      @staus = 200
      return ret
    rescue
      @status = 404 # http ERROR named 'REsource not found'
      puts $ERROR_INFO
    end
  end
end

