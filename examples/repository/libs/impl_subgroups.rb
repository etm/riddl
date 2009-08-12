# Creates an ATOM-Feed with all included subgroups in given group
class SubgroupsGET < Riddl::Implementation
  include MarkUSModule

  $url = 'http://localhost:9292/'

  def response
    if File.exist?("repository/#{@r[0]}/#{@r.last}") == false
      @status = 410 # 410: Gone
      p "Group not found"
      return
    end

    groups = []
    dirs = Dir["repository/#{@r[0]}/#{@r.last}/*"]
    dirs.each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end

    @status = 200 # 200: OK
    Riddl::Parameter::Complex.new("list-of-subgroups","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
        title_ 'List of subgroups in group " ' + @r.last + '"'
        updated_ File.mtime("repository/#{@r[0]}/#{@r.last}").xmlschema
        generator_ 'My Repository at local host', :uri => "#{$url}"
        id_ "#{$url}#{@r[0]}/#{@r.last}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}#{@r[0]}/#{@r.last}/"
        groups.each do |g|
          entry_ :lang => 'EN' do
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
class SubgroupPOST < Riddl::Implementation
  def response
    begin
      Dir.mkdir("repository/groups/#{@r[1]}/#{@p[0].value}")
      @status = 201 # 201: Created
    rescue
      @status = 409 # http ERROR named 'Conflict'
      puts 'Creating subgroup failed because of: ' + $ERROR_INFO 
    end
  end
end

# Creates a new Subgroup in the repository
class SubgroupPUT < Riddl::Implementation
  def response
    oldDir = nil
    # Check if subgroup exists
    if File.exist?("repository/groups/#{@r[1]}/#{@r[2]}") == false
      @status = 410 # 410: Gone
      puts 'Updating subgroup failed because subgroup does not exists.'
      return
    end
    begin # Renaming subgroup
      File.rename("repository/groups/#{@r[1]}/#{@r[2]}", "repository/groups/#{@r[1]}/#{@p[0].value}")
    rescue
      @status = 409 # 409: Conflict
      puts 'Updating subgroup failed because of: ' + $ERROR_INFO 
      return
    end
    @status = 200 # 200: OK
  end
end

# Creates a new Subgroup in the repository
class SubgroupDELETE < Riddl::Implementation
  def response
    begin
      FileUtils.rm_r "repository/groups/#{@r[1]}/#{@r[2]}"
    rescue
      @status = 410
      puts 'Deleting subgroup failed because of: ' + $ERROR_INFO 
      return
    end
    @status = 200
  end
end

