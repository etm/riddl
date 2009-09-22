class Count < Riddl::Implementation
  include MarkUSModule

  def response
    groups = []
    @r.pop
    Dir["repository/#{@r.join("/")}/*"].sort.each do |f|
      if File::directory? f
        groups << File::basename(f) 
      end 
    end
    Riddl::Parameter::Simple.new("count", groups.size)      
  end
end
