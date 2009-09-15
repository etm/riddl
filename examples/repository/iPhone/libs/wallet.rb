class AddToWallet < Riddl::Implementation
  include MarkUSModule

  def response
    #pp @r
    #["08c5c293b7c28c0910ebc4848136e058", "wallet"]
    # Create user dir if not exist
    if File.exists?("user/#{@r.join("/")}/#{@p[0].value}")
      puts "Directory: user/#{@r.join("/")}/#{@p[0].value} already exists" 
#      @status = 409 # Conflict
      Riddl::Parameter::Complex.new("html","text/html") do
        div_ :id => 'rescue' do  
          div_ :class => "toolbar" do
            h1_ "Wallet"
            a_ "Back", :class => "back button", :href => "#"
          end
          div_ :class => "message", :align=>"center" do
            br_
            br_
            h3_ "Resouce is already in your wallet", :style=>"font-size: 24pt; color: #FFFFFF"
          end
        end
      end
    else
      FileUtils.mkdir_p("user/#{@r.join("/")}/#{@p[0].value}")
      Riddl::Parameter::Complex.new("html","text/html") do
        div_ :id => 'rescue' do  
          div_ :class => "toolbar" do
            h1_ "Wallet"
            a_ "Back", :class => "back button", :href => "#"
          end
          div_ :class => "message", :align=>"center" do
            br_
            br_
            h3_ "Resource added to your wallet", :style=>"font-size: 24pt; color: #FFFFFF"
          end
        end
      end
    end
  end
end


class GetWallet < Riddl::Implementation
  include MarkUSModule

  def response
    # If Wallet is empty
    if File.exist?("user/#{@r[0]}/wallet") == false
      p "Wallet does not exists"
      Riddl::Parameter::Complex.new("html","text/html") do
        div_ :id => 'rescue' do  
          div_ :class => "toolbar" do
            h1_ "Wallet"
            a_ "Back", :class => "back button", :href => "#"
          end
          div_ :class => "message", :align=>"center" do
            br_
            br_
            h3_ "Your wallet is empty", :style=>"font-size: 24pt; color: #FFFFFF"
          end
        end
      end
    else
    # Wallet is not empty
      Riddl::Parameter::Complex.new("html","text/html") do
        div_ :id => 'rescue' do  
          div_ :class => "toolbar" do
            h1_ "Wallet"
            a_ "Back", :class => "back button", :href => "#"
          end
          div_ :id => 'walletIndex', :class => "edgetoedge" do
            ul_ do
              createEntry ("user/#{@r[0]}/wallet/*")
            end
          end
        end
      end
    end
  end

  def createEntry(dir)
    entries = Dir[dir]
    if entries.size != 0
      entries.sort.each do |f|
        createEntry(f + "/*")
      end
    else 
      x = dir.split("/")
      li_ x[3...x.size-1].join("/")
    end
  end
end

