class SubgroupsGET < Riddl::Implementation
  include MarkUSModule

  $url = 'http://localhost:9292/'

  def response
    groups = []
    Dir["repository/#{@r[0]}/#{@r.last}/*"].each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
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
