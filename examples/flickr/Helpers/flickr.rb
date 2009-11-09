require 'digest/md5'

class FlickrHelper
  def initialize(dir)
    @api_key = File.read(dir + '/flickr.key').strip
    @api_secret = File.read(dir + '/flickr.secret').strip
    if File.exists?(dir + 'flickr.token')
      @auth_token = File.read(dir + 'flickr.token').strip
    else  
      @auth_token = "simulated"
    end
  end

  attr_reader :api_key, :api_secret, :auth_token

  def sign(ary)
    sig = @api_secret
    ary.sort{|a,b|a.name<=>b.name}.each do |e|
      sig += "#{e.name}#{e.value}" if e.class == Riddl::Parameter::Simple
    end
    Digest::MD5.hexdigest(sig)
  end
end
