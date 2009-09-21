class Show
  include MarkUSModule

  def showPage( title, message, status=nil )
    Riddl::Parameter::Complex.new("html","text/html") do
      div_ :id => 'wallet' do  
=begin
        div_ :class => "toolbar" do
          h1_ title
          a_ "Back", :class => "back button", :href => "#"
        end
=end
        div_ :class => "message", :align=>"center" do
          br_
          br_
          h3_ message, :style=>""
          h3_ "HTTP-Status: (" + status + ")", :style=>"" if status != nil
        end
      end
    end
  end
end
