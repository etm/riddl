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
        div_  :align=>"center" do
          p_ message, :class => "errorText"
          br_  if status != nil
          p_ "HTTP-Status: (" + status + ")", :class => "errorText" if status != nil
        end
      end
    end
  end
end
