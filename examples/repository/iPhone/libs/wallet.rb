class DeleteFromWallet < Riddl::Implementation
  include MarkUSModule

  def response
    if File.exists?("user/#{@r.join("/")}/#{@p[0].value}") == false
      puts "Directory: user/#{@r.join("/")}/#{@p[0].value} does not exist" 
      @status = 410 # Gone
    else
      FileUtils.rm("user/#{@r.join("/")}/#{@p[0].value}/subscribed")
    end
  end
end

class AddToWallet < Riddl::Implementation
  include MarkUSModule

  def response
    # Create user dir if not exist
    if File.exists?("user/#{@r.join("/")}/#{@p[0].value}/subscribed")
      puts "Directory: user/#{@r.join("/")}/#{@p[0].value} already exists" 
      @status = 409 # Conflict
    else
      begin
        FileUtils.mkdir_p("user/#{@r.join("/")}/#{@p[0].value}")
      rescue
        p "Resource has been subscribed befor"
      end
      File.new("user/#{@r.join("/")}/#{@p[0].value}/subscribed","w")
    end
  end
end


class GetWallet < Riddl::Implementation
  include MarkUSModule

  def response
    @headers << Riddl::Header.new("Cache-Control","No-Cache")
    entries = Array.new
    findEntries("user/#{@r[0]}/wallet", entries)
    # If Wallet is empty
    if (entries.size == 0)
      message = "Wallet does not exists or is empty"
      p message
      return Show.new().showPage("Wallet", message, nil, true)
    else
    # Wallet is not empty
      html = div_ :id => 'wallet' do  
        div_ :class => "toolbar" do
          h1_ "Wallet"
          a_ "Back", :class => "back button", :href => "#"
        end
        div_ :style=>"text-align: center;" do 
          p_ "Tab resource to query it!", :class=>"infoText";
        end
        div_ :id => 'walletIndex', :class => "edgetoedge" do
          ul_ :id=>"walletEntries" do
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
  end

  def findEntries(dir, entries)
    actDir = Dir[dir+"/*"]

    actDir.sort.each do |f|
      if File::directory? f
        findEntries(f, entries)
      elsif File::basename(f) == "subscribed"
        tmp = f.split("/")
        entries << tmp[3...tmp.size-1].join("/")
      end
    end
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
        a_ "Query", :href=>"#disposeQuery", :onClick=>"generateQueryForm('#{entry}')", :class=>"greenButton slideup"
        a_ "Delete", :onclick=>"removeFromWallet('#{Digest::MD5.hexdigest(entry)}', 'wallet')", :class=>"redButton goback"
        a_ "Back", :href=>"#", :class=>"whiteButton goback"
      end
    end
    html
  end
end

