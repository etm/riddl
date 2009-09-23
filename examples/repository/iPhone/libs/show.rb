class Show
  include MarkUSModule

  def showPage( title, message, status=nil, toolbar=false )
    Riddl::Parameter::Complex.new("html","text/html") do
      div_ :id => 'wallet' do  
        if (toolbar)
          div_ :class => "toolbar" do
            h1_ title
            a_ "Back", :class => "back button", :href => "#"
          end
        end
        div_  :class => "errorText" do
          p_ message
          br_  if status != nil
          p_ "HTTP-Status: (" + status + ")" if status != nil
        end
      end
    end
  end
end
