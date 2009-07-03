class ServicesGET < Riddl::Implementation
  include MarkUSModule

  $url = 'http://localhost:9292/'

  def response
    groups = []
    Dir["repository/#{@r[0]}/#{@r[1]}/#{@r.last}/*"].each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end  

    Riddl::Parameter::Complex.new("list-of-services","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
        title_ 'List of services in subgroup " ' + @r.last + '"'
        updated_ File.mtime("repository/#{@r[0]}/#{@r[1]}/#{@r.last}").xmlschema
        generator_ 'My Repository at local host'
        id_ "#{$url}#{@r[0]}/#{@r[1]}/#{@r.last}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}#{@r[0]}/#{@r[1]}/#{@r.last}/"
        groups.each do |g|
          entry_ do
            id_ "#{$url}#{@r[0]}/#{@r[1]}/#{@r.last}/#{g}"
            detailFile = XML::Smart::open("repository/#{@r[0]}/#{@r[1]}/#{@r.last}/#{g}/details.xml")
            link_ detailFile.find("string(/details/URI)")
            updated_ File.mtime("repository/#{@r[0]}/#{@r[1]}/#{@r.last}/#{g}").xmlschema
          end
        end  
      end
    end  
  end
end
