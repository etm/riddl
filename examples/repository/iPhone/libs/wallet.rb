require 'digest/md5'


class DeleteFromWallet < Riddl::Implementation
  include MarkUSModule

  def response
    #pp @r
    pp @p[0].value
    #["08c5c293b7c28c0910ebc4848136e058", "wallet"]
    # Create user dir if not exist
    if File.exists?("user/#{@r.join("/")}/#{@p[0].value}") == false
      puts "Directory: user/#{@r.join("/")}/#{@p[0].value} does not exist" 
      @status = 410 # Conflict
    else
      FileUtils.rm_r("user/#{@r.join("/")}/#{@p[0].value}")
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
    if File.exists?("user/#{@r.join("/")}/#{@p[0].value}")
      puts "Directory: user/#{@r.join("/")}/#{@p[0].value} already exists" 
      @status = 409 # Conflict
    else
      FileUtils.mkdir_p("user/#{@r.join("/")}/#{@p[0].value}")
    end
  end
end


class GetWallet < Riddl::Implementation
  include MarkUSModule

  def response
    # If Wallet is empty
    if ((File.exist?("user/#{@r[0]}/wallet") == false) || (Dir["user/#{@r[0]}/wallet/*"].size == 0))
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
      Riddl::Parameter::Complex.new("html","text/html") do
        div_ :id => 'wallet' do  
          div_ :class => "toolbar" do
            h1_ "Wallet"
            a_ "Back", :class => "back button", :href => "#"
          end
          div_ :id => 'walletIndex', :class => "edgetoedge" do
            ul_ :id=>"walletEntries" do
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
      li_ :style=>"vertical-align: center;", :id=>Digest::MD5.hexdigest(x[3...x.size-1].join("-")) do
        img_ :src=>"../js/custom/minusButton.png", :onclick=>"removeFromWallet('#{Digest::MD5.hexdigest(x[3...x.size-1].join("-"))}', 'wallet')", :style=>"vertical-align: center;"
#        img_ :src=>"../js/custom/minusButton.png", :onclick=>"removeFromWallet('#{x[3...x.size-1].join("/")}', 'wallet')", :style=>"vertical-align: center;"
        span_ x[3...x.size-1].join("/"), :style=>"display:inline; margin-left:10px;vertical-align: center;"
      end
    end
  end
end

