class Groups < Riddl::Implementation
  include MarkUSModule
  $url = 'http://localhost:9292/'
  
  def response
    groups = []
    Dir['repository/groups/*'].each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end  
    end  

    Riddl::Parameter::Complex.new("list-of-groups","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/atom' do
        title_ 'List of groups'
        updated_ 'No date at the monent'
        generator_ 'My Repository at local host'
        id_ "#{$url}groups/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{$url}groups/"
        groups.each do |g|
          entry_ do
            id_ "#{$url}groups/#{g}/"
            link_ "#{$url}groups/#{g}/"
            updated_ File.mtime("repository/groups/#{g}").xmlschema
          end
        end  
      end
    end  
  end
end