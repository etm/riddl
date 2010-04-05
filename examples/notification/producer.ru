#\ -p 9291
require 'pp'
require '../../lib/ruby/server'
require '../../lib/ruby/utils/fileserve'
require '../../lib/ruby/utils/declaration'
require '../../lib/ruby/utils/notification_provider'

use Rack::ShowStatus

run Riddl::Server.new(::File.dirname(__FILE__) + '/producer-declaration.xml') {
  accessible_description true
  ndir = ::File.dirname(__FILE__) + '/notifications/'
  xsls = {
    :overview => '/xsls/overview.xsl',
    :subscriptions => '/xsls/subscriptions.xsl'
  }

  on resource do
    run Riddl::Utils::Declaration::Description, description_string if get 'riddl-description-request'
    run Riddl::Utils::FileServe, "implementation/index.html" if get
    on resource 'oliver' do
      run Riddl::Utils::FileServe, "implementation/oliver.html" if get
    end  
    on resource 'juergen' do
      run Riddl::Utils::FileServe, "implementation/juergen.html" if get
    end
    on resource 'notifications' do
      use Riddl::Utils::Notification::Provider::implementation(ndir,xsls)
    end
    on resource 'xsls' do
      on resource do
        run Riddl::Utils::FileServe, "xsls"  if get
      end  
    end  
  end
}
