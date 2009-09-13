class ServicesGET < Riddl::Implementation
  include MarkUSModule

  $url = e['HTTP_HOST']

  def response
    if File.exist?("repository/#{@r[0]}/#{@r[1]}/#{@r.last}") == false
      @status = 410 # 410: Gone
      puts "Subgroup not found"
      return
    end
    groups = []
    Dir["repository/#{@r[0]}/#{@r[1]}/#{@r.last}/*"].each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end  

    Riddl::Parameter::Complex.new("list-of-services","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
        title_ 'List of services in subgrouputs " ' + @r.last + '"'
        updated_ File.mtime("repository/#{@r[0]}/#{@r[1]}/#{@r.last}").xmlschema
        generator_ 'My Repository at local host', :uri => "#{$url}"
        id_ "#{$url}#{@r[0]}/#{@r[1]}/#{@r.last}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}#{@r[0]}/#{@r[1]}/#{@r.last}/"
        schema_ do
          properties_ "#{$url}#{@r[0]}/#{@r[1]}?properties.schema"
          queryInput_ "#{$url}#{@r[0]}/#{@r[1]}?queryInput.schema"
          queryOutput_ "#{$url}#{@r[0]}/#{@r[1]}?queryOutput.schema"
          invokeInput_ "#{$url}#{@r[0]}/#{@r[1]}?invokeInput.schema"
          invokeOutput_ "#{$url}#{@r[0]}/#{@r[1]}?invokeOutput.schema"
        end

        groups.each do |g|
          entry_ :lang => 'EN' do
            id_ "#{g}"
            detailFile = XML::Smart::open("repository/#{@r[0]}/#{@r[1]}/#{@r.last}/#{g}/details.xml")
            link_ detailFile.find("string(/details/URI)")
            updated_ File.mtime("repository/#{@r[0]}/#{@r[1]}/#{@r.last}/#{g}").xmlschema
          end
        end  
      end
    end  
  end
end

# Creates a new Sevice in the repository
class ServicesPOST < Riddl::Implementation
  def response
    begin
      xmlString = @p[1].value.read
      x = XML::Smart.string(xmlString)
      if x.validate_against(XML::Smart::open("rngs/details-of-service.rng"))
        Dir.mkdir("repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}")
        # Saving the details of the service into the acording XMl file
        detailsFile = File.new("repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}/details.xml", "w")
        detailsFile.write(xmlString)
        detailsFile.close()
        @status = 201   # 201: Created
      else
        @status = 415 # 415: Unsupported Media Type
        puts "XML doesn't match the RNG schema (details-of-service.rng)"
      end
    rescue
      @status = 409 # http ERROR named 'Conflict'
      puts $ERROR_INFO
    end
  end
end

# Updates a Sevice in the repository
class ServicesPUT < Riddl::Implementation
  def response
    if File.exist?("repository/groups/#{@r[1]}/#{@r[2]}/#{@r[3]}") == false
      @status = 410 # 410: Gone
      puts 'Updating service failed because service does not exists.'
      return
    end
    begin
      xmlString = @p[1].value.read
      x = XML::Smart.string(xmlString)
      if x.validate_against(XML::Smart::open("rngs/details-of-service.rng"))
        File.rename("repository/groups/#{@r[1]}/#{@r[2]}/#{@r[3]}","repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}")
        # Saving the details of the service into the acording XMl file
        detailsFile = File.new("repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}/details.xml", "w")
        detailsFile.write(xmlString)
        detailsFile.close()
        @staus = 200   # 200: OK
      else
        @status = 415 # 415: Unsupported Media Type
        puts "XML doesn't match the RNG schema (details-of-service.rng)"
      end
    rescue
      @status = 409 # http ERROR named 'Conflict'
      puts $ERROR_INFO
    end
  end
end

# Creates a new Sevice in the repository
class ServicesDELETE < Riddl::Implementation
  def response
    begin
      FileUtils.rm_r "repository/groups/#{@r[1]}/#{@r[2]}/#{@r[3]}"
      @staus = 200
    rescue
      @status = 410 # 410: Gone
      puts $ERROR_INFO
    end
  end
end

