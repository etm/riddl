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
class GroupsPOST < Riddl::Implementation
  def response
    begin
      p "Generating group named '#{@p[0].value}' ...."
      Dir.mkdir("repository/groups/#{@p[0].value}")
      @staus = 200
      p 'OK (200)'
    rescue
      @status = 409 # http ERROR named 'Conflict'
      p $ERROR_INFO
    end
  end
end
