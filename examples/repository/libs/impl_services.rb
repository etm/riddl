require 'open-uri'

class ServicesGET < Riddl::Implementation
  include MarkUSModule


  def response
    $url = "http://" + @e['HTTP_HOST'] + "/"
    if File.exist?("repository/#{@r[0]}/#{@r[1]}/#{@r.last}") == false
      @status = 410 # 410: Gone
      puts "Subgroup not found"
      return
    end
    groups = []
    Dir["repository/#{@r[0]}/#{@r[1]}/#{@r.last}/*"].sort.each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end  

    Riddl::Parameter::Complex.new("list-of-services","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
        title_ 'List of services in subgroup "' + @r.last + '"'
        updated_ File.mtime("repository/#{@r[0]}/#{@r[1]}/#{@r.last}").xmlschema
        generator_ 'RESCUE', :uri => "#{$url}"
        id_ "#{$url}#{@r[0]}/#{@r[1]}/#{@r.last}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}#{@r.join('/')}/"
        schema_ do
          properties_ "#{$url}#{@r[0]}/#{@r[1]}?properties"
          static_ "#{$url}#{@r[0]}/#{@r[1]}?static"
          queryInput_ "#{$url}#{@r[0]}/#{@r[1]}?queryInput"
          queryOutput_ "#{$url}#{@r[0]}/#{@r[1]}?queryOutput"
          invokeInput_ "#{$url}#{@r[0]}/#{@r[1]}?invokeInput"
          invokeOutput_ "#{$url}#{@r[0]}/#{@r[1]}?invokeOutput"
        end

        groups.each do |g|
          entry_ :lang => 'EN' do
            id_ "#{g}"
            link_ "#{$url}#{@r.join('/')}/#{g}/"
            updated_ File.mtime("repository/#{@r.join('/')}/#{g}").xmlschema
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
      x = XML::Smart::string(xmlString)
      # Check if provided white information fits to shema
      valide = true
      begin
        valide = false if x.validate_against(XML::Smart::open("rngs/details-of-service.rng")) == false
        # Check if static properties fits to schema
        staticURI = x.find("string(/details/service/staticProperties)")
        staticProps = XML::Smart::string(open(staticURI).read)
        schema = XML::Smart::open("repository/#{@r[0]}/#{@r[1]}/properties.xml")
        xslt = XML::Smart::open("rngs/static-properties.xsl")
        valide = false if staticProps.validate_against(XML::Smart::string(schema.transform_with(xslt))) == false
      rescue
        valide = false
      end

      if valide == false
        @status = 415 # 415: Unsupported Media Type
        puts "XML doesn't match the RNG schema"
        return
      end

      # Create entry if everything is valide
      Dir.mkdir("repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}")
      # Saving the details of the service into the acording XMl file
      detailsFile = File.new("repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}/details.xml", "w")
      detailsFile.write(xmlString)
      detailsFile.close()
      @status = 201   # 201: Created
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
      # Check if provided white information fits to shema
      valide = true
      begin
        valide = false if x.validate_against(XML::Smart::open("rngs/details-of-service.rng")) == false
        # Check if static properties fits to schema
        staticURI = x.find("string(/details/service/staticProperties)")
        staticProps = XML::Smart::string(open(staticURI).read)
        schema = XML::Smart::open("repository/#{@r[0]}/#{@r[1]}/properties.xml")
        xslt = XML::Smart::open("rngs/static-properties.xsl")
        valide = false if staticProps.validate_against(XML::Smart::string(schema.transform_with(xslt))) == false
      rescue
        valide = false
      end

      if valide == false
        @status = 415 # 415: Unsupported Media Type
        puts "XML doesn't match the RNG schema"
        return
      end

      File.rename("repository/groups/#{@r[1]}/#{@r[2]}/#{@r[3]}","repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}")
      # Saving the details of the service into the acording XMl file
      detailsFile = File.new("repository/groups/#{@r[1]}/#{@r[2]}/#{@p[0].value}/details.xml", "w")
      detailsFile.write(xmlString)
      detailsFile.close()
      @staus = 200   # 200: OK
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

