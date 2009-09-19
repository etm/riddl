class Show
  include MarkUSModule

  def showPage( title, message, status=nil )
    Riddl::Parameter::Complex.new("html","text/html") do
      div_ :id => 'wallet' do  
        div_ :class => "toolbar" do
          h1_ title
          a_ "Back", :class => "back button", :href => "#"
        end
        div_ :class => "message", :align=>"center" do
          br_
          br_
          h3_ message, :style=>"font-size: 24pt;"
          h3_ "HTTP-Status: (" + status + ")", :style=>"font-size: 18pt;" if status != nil
        end
      end
    end
  end
end
