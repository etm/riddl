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
      # Checking properties
      properties = @p[1].value.read
      x = XML::Smart.string(properties)
      if x.validate_against(XML::Smart::open("rngs/properties.rng")) == false
        @status = 415 # 415: Unsupported Media Type
        puts "File doesn't match the RNG schema (properties.rng)"
      end 
      # Checking queryInput
      queryInput = @p[2].value.read
      x = XML::Smart.string(queryInput)
      if x.validate_against(XML::Smart::open("rngs/query-input.rng")) == false
        @status = 415 # 415: Unsupported Media Type
        puts "File doesn't match the RNG schema (query-input.rng)"
      end 
      # Chekcing queryOutput
      queryOutput = @p[3].value.read
      x = XML::Smart.string(queryOutput)
      if x.validate_against(XML::Smart::open("rngs/query-output.rng")) == false
        @status = 415 # 415: Unsupported Media Type
        puts "File doesn't match the RNG schema (query-output.rng)"
      end 
      # Checking invokeInput
      invokeInput = @p[4].value.read
      x = XML::Smart.string(invokeInput)
      if x.validate_against(XML::Smart::open("rngs/invoke-input.rng")) == false
        @status = 415 # 415: Unsupported Media Type
        puts "File doesn't match the RNG schema (invoke-input.rng)"
      end 
      # Chekcing invokeOutput
      invokeOutput = @p[5].value.read
      x = XML::Smart.string(invokeOutput)
      if x.validate_against(XML::Smart::open("rngs/invoke-output.rng")) == false
        @status = 415 # 415: Unsupported Media Type
        puts "File doesn't match the RNG schema (invoke-output.rng)"
      end 
      if @status == nil
        begin
          FileUtils.mkdir "repository/#{@r[0]}/#{@p[0].value}"
          # Writing properties into file
          detailsFile = File.new("repository/#{@r[0]}/#{@p[0].value}/properties.xml", "w")
          detailsFile.write(properties)
          detailsFile.close()

          # Writing queryInput into file
          detailsFile = File.new("repository/#{@r[0]}/#{@p[0].value}/query-input.xml", "w")
          detailsFile.write(queryInput)
          detailsFile.close()

          # Writing queryOutput into file
          detailsFile = File.new("repository/#{@r[0]}/#{@p[0].value}/query-output.xml", "w")
          detailsFile.write(queryOutput)
          detailsFile.close()

          # Writing invokeInput into file
          detailsFile = File.new("repository/#{@r[0]}/#{@p[0].value}/invoke-input.xml", "w")
          detailsFile.write(invokeInput)
          detailsFile.close()

          # Writing invokeOutput into file
          detailsFile = File.new("repository/#{@r[0]}/#{@p[0].value}/invoke-output.xml", "w")
          detailsFile.write(invokeOutput)
          detailsFile.close()
          @status = 201  # 201: Created
        rescue
          @status = 409 # http ERROR named 'Conflict'
          puts $ERROR_INFO
        end
      end
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


class GroupProperties < Riddl::Implementation
  include MarkUSModule

  $url = 'http://localhost:9292/'
  
  def response
    fileName = "repository/#{@r[0]}/#{@r[1]}/properties.xml"
    if File.exist?(fileName) == false
      puts "Can not read #{filename}"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("properties","text/xml") do
      mystring = ''
      File.open(fileName, "r") { |f|
        mystring = f.read
      }
      mystring
    end
  end
end


class GroupQueryInput < Riddl::Implementation
  include MarkUSModule

  $url = 'http://localhost:9292/'
  
  def response
    fileName = "repository/#{@r[0]}/#{@r[1]}/query-input.xml"
    if File.exist?(fileName) == false
      puts "Can not read #{filename}"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("query-input","text/xml") do
      xmlFile = XML::Smart::open(fileName)
      xslt = XML::Smart::open("rngs/query-input.xsl")
      xmlFile.transform_with(xslt)
    end
  end
end

