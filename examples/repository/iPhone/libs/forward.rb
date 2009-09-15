require 'digest/md5'

class Forward < Riddl::Implementation
  def response
    @headers << Riddl::Header.new("Location","/" + Digest::MD5.hexdigest(Time.now.to_s + Kernel.rand.to_s))
    @status = 302
  end
end
