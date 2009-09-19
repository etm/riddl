class DeleteFromWallet < Riddl::Implementation
  include MarkUSModule

  def response
    #pp @r
    #["08c5c293b7c28c0910ebc4848136e058", "wallet"]
    pp "DELETE: " + @p[0].value
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
    #pp @r
    #pp @p[0].value
    #["08c5c293b7c28c0910ebc4848136e058", "wallet"]
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
    entries = Array.new
    findEntries("user/#{@r[0]}/wallet", entries)
    # If Wallet is empty
    if (entries.size == 0)
      p "Wallet does not exists or is empty"
      Riddl::Parameter::Complex.new("html","text/html") do
        div_ :id => 'wallet' do  
          div_ :class => "toolbar" do
            h1_ "Wallet"
            a_ "Back", :class => "back button", :href => "#"
          end
          div_ :class => "message", :align=>"center" do
            br_
            br_
            h3_ "Your wallet is empty", :style=>"font-size: 24pt;"
          end
        end
      end
    else
    # Wallet is not empty
      html = div_ :id => 'wallet' do  
        div_ :class => "toolbar" do
          h1_ "Wallet"
          a_ "Back", :class => "back button", :href => "#"
        end
        div_ :style=>"text-align: center;" do span_ "<br/><b>Touch resource to query it!</b><br/><br/>", :style=>"font-size: 16pt; color: green;" end
        div_ :id => 'walletIndex', :class => "edgetoedge" do
          ul_ :id=>"walletEntries" do
            entries.each do |entry| 
              li_ :style=>"vertical-align: middle;", :id=>Digest::MD5.hexdigest(entry) do
                table_ :style=>"width: 100%;" do 
                  tr_ do 
                    td_ :style=>"width:100%;" do 
                      a_ entry, :href=>"query?pointOfEntry=" + entry, :style=>"display:inline; margin-left:5px;vertical-align: center;", :id=>"span"+Digest::MD5.hexdigest(entry), :class=>"flip"
                    end 
                    td_ :style => "vertical-align:middle;"do 
                      a_ :href=>"#confirm" + Digest::MD5.hexdigest(entry), :class=>"slideup" do 
                        img_ :src=>"../js/custom/minusButton.png"
                      end
                    end
                  end
                end
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
          h1_ "Confirm"
        end
        br_
        br_
        h4_ "Do you want to remove the resoure '#{entry}' from your wallet?", :style=>"font-size: 20pt; text-align:center;"
        br_
        br_
        a_ "Yes", :style=>"margin:0 10px;color:green", :onclick=>"removeFromWallet('#{Digest::MD5.hexdigest(entry)}', 'wallet')", :class=>"whiteButton goback"
        br_
        a_ "Cancel", :style=>"margin:0 10px;color:red", :href=>"#", :class=>"whiteButton goback"
      end
    end
    html
  end
end

