
class SubgroupsGET < Riddl::Implementation
  include MarkUSModule

  $url = 'http://localhost:9292/'

  def response
    groups = []
    dirs = Dir["repository/#{@r[0]}/#{@r.last}/*"]
    dirs.each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end
    if dirs.size == 0
      @status = 404 # Error 404: Resource not found
      puts "Error: Subgroup not found\n"
      return
    end

    Riddl::Parameter::Complex.new("list-of-subgroups","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
        title_ 'List of subgroups in group " ' + @r.last + '"'
        updated_ File.mtime("repository/#{@r[0]}/#{@r.last}").xmlschema
        generator_ 'My Repository at local host'
        id_ "#{$url}#{@r[0]}/#{@r.last}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}#{@r[0]}/#{@r.last}/"
        groups.each do |g|
          entry_ do
            id_ "#{$url}#{@r[0]}/#{@r.last}/#{g}/"
            link_ "#{$url}#{@r[0]}/#{@r.last}/#{g}/"
            updated_ File.mtime("repository/#{@r[0]}/#{@r.last}/#{g}").xmlschema
          end
        end  
      end
    end  
  end
end

# Creates a new Subgroup in the repository
class SubgroupsPOST < Riddl::Implementation
  def response
    begin
      p "Generating subgroup in '#{@r[1]}' named '#{@p[0].value}' ...."
      begin
        Dir.mkdir("repository/groups/#{@r[1]}/#{@p[0].value}")
      rescue
        @status = 404
        puts 'Creating subgroup failed because of\n#' + $ERROR_INFO 
        return
      end
      @status = 200
      puts 'OK (200)'
    rescue
      @status = 409 # http ERROR named 'Conflict'
      puts $ERROR_INFO
    end
  end
end

# Creates a new Subgroup in the repository
class SubgroupsPUT < Riddl::Implementation
  def response
    @staus = 501 # HTTP-Error 'Not supported'
  end
end

# Creates a new Subgroup in the repository
class SubgroupsDELETE < Riddl::Implementation
  def response
    begin
      p "Deleting subgroup in '#{@r[1]}' named '#{@p[0].value}' ...."
      begin
        # Dir.mkdir("repository/groups/#{@r[1]}/#{@p[0].value}")
        FileUtils.rm_rf 'repository/groups/#{@r[1]}/#{@p[0].value}'
      rescue
        @status = 404
        puts 'Deleting subgroup failed because of\n#' + $ERROR_INFO 
        return
      end
      @status = 200
      puts 'OK (200)'
    rescue
      @status = 404 # http ERROR named 'Not found'
      puts $ERROR_INFO
    end
  end
end

