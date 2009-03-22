require '../../lib/riddl'

use Rack::ShowStatus

run Riddl.new do
  description "description.xml"
  on resource 'hellos' do
    run 'e' if post 'hello'
    run 'e' if post 'hello-form'
    run 'e' if get '*'
    run 'e' if get 'type-html'
    on resource do
      run 'd' if get '*'
      run 'd' if put 'hello'
      run 'd' if delete '*'
    end
  end
end
