require '../../lib/riddl'

use Rack::ShowStatus

run Rum.new do
  on resource 'hellos' do
    if post 'hello': run 'e' end
    if post 'hello-form': run 'e' end
    if get '*': run 'e' end
    if get 'type-html': run 'e' end
    on resource do
      if get '*': run 'd' end
      if put 'hello': run 'd' end
      if delete '*': run 'd' end
    end
  end
end
