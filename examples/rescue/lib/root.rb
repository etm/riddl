class GetDescription < Riddl::Implementation

  def response
    if File.exist?("description.xml") == false
      puts "Can not read description.xml"
      @status = 410 # 410: Gone
      return
    end
    Riddl::Parameter::Complex.new("description","text/xml", File.open("description.xml", "r"))
  end
end

class GenerateFeed < Riddl::Implementation
  include MarkUSModule

  def response
    url = "http://" + @env['HTTP_HOST'] + "/"
    groups = Array.new
    Dir["#{@r.join("/")}/*"].sort.each do |f|
      groups << File::basename(f) if File::directory? f
    end
    Riddl::Parameter::Complex.new("atom-feed","text/xml") do
      feed__ :xmlns => 'http://www.w3.org/2005/Atom' do
        title_ "List of groups at #{url}"
        updated_ File.mtime("#{@r.join("/")}").xmlschema
        generator_ 'RESCUE', :uri => "#{url}"
        id_ "#{url}#{@r.join("/")}/"
        link_ :rel => 'self', :type => 'application/atom+xml', :href => "#{url}#{@r.join("/")}/"
        parse_interface(@r[1], url) if @r.length > 1
        groups.each do |g|
          entry_ do 
            title_ "#{g}"
            author_ do name_ "RESCUE" end
            id_ "#{url}#{@r.join("/")}/#{g}/"
            link_ g, :href=>"#{url}#{@r.join("/")}/#{g}/"
            updated_ File.mtime("#{@r.join("/")}/#{g}").xmlschema
          end
        end
      end
    end
  end

  def parse_interface(group_name, url)
    xml = XML::Smart.open("groups/#{group_name}/interface.xml")
    schema_ do
      operations = xml.find("/interface/operations/*")
      operations.each do |o|
        operation_ :name=>"#{o.name.name}" do
          message_ :type=>"input", :href=>"#{url}/groups/#{group_name}/operations/#{o.name.name}?input"
          message_ :type=>"output", :href=>"#{url}/groups/#{group_name}/operations/#{o.name.name}?output"
        end
      end
      properties_ :href=>"#{url}/groups/#{group_name}?properties"
    end
  end
end

