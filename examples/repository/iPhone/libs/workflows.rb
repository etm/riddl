class GetWorkflows < Riddl::Implementation
  include MarkUSModule

  def response
    entries = Array.new
    Dir["user/#{@r.join("/")}/*"].sort.each do |f|
      if File::directory? f
        entries << File::basename(f) 
      end  
    end  
    html = div_ :id => 'workflows' do  
      div_ :class => "toolbar" do
        h1_ "Workflows"
        a_ "Back", :class => "back button", :href => "#"
        a_ "Add", :class => "slideup button", :href => "#addWorkflow"
      end
      div_ :id => 'workflowIndex', :class => "rounded" do
        ul_ :id=>"workflowEntries" do
          entries.each do |entry| 
            li_ :style=>"vertical-align: middle;", :id=>Digest::MD5.hexdigest(entry) do
              a_ entry, :href=>"#confirm" + Digest::MD5.hexdigest(entry), :class=>"slideup"
            end
          end
        end
      end
    end
    html += createConfirm(entries)
    Riddl::Parameter::Complex.new("html","text/html", html)
  end

  def createConfirm(entries)
    html = ""
    entries.sort.each do |entry|
      html = div_ :id=>"confirm" + Digest::MD5.hexdigest(entry) do
        div_ :class => "toolbar" do
          a_ "Back", :class => "back button", :href => "#"
          h1_ "Res: " + entry
        end
        p_ "What do you want to do with the resource", :class=>"infoText"
        p_ entry, :class=>"infoText", :id=>"p" + Digest::MD5.hexdigest(entry)
        a_ "Details", :href=>"#disposeQuery", :onClick=>"generateQueryForm('#{entry}')", :class=>"greenButton slideup"
        a_ "Delete", :onclick=>"removeWorkflow('#{entry}', '#{Digest::MD5.hexdigest(entry)}')", :class=>"redButton goback"
        a_ "Back", :href=>"#", :class=>"whiteButton goback"
      end
    end
    html
  end
end



class DeleteWorkflow < Riddl::Implementation
  def response
    if File.exists?("user/#{@r.join("/")}")
      #FileUtils.rm_r "user/#{@r.join("/")}"
    else
      @status = 410 # Gone
    end
  end
end



class AddWorkflow < Riddl::Implementation
  def response
    if File.exists?("user/#{@r.join("/")}/#{@p[0].value}")
      puts "Directory: user/#{@r.join("/")}/#{@p[0].value} already exists" 
      @status = 409 # Conflict
    else
      begin
        FileUtils.mkdir_p("user/#{@r.join("/")}/#{@p[0].value}")
      rescue
        p "Resource has been subscribed befor"
      end
    end
  end
end


