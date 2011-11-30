require 'rake'
require 'pp'
require 'rubygems/package_task'

spec = eval(File.read('riddl.gemspec'))
Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
  `rm pkg/*.gem`
  `ln -sf #{pkg.name}.gem pkg/riddl.gem`
end

