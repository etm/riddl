require 'rake'
require 'rake/gempackagetask'

spec = eval(File.read('riddl.gemspec'))
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
  `rm pkg/*.gem`
  `ln -sf riddl-#{pkg.version.to_s}.gem pkg/riddl.gem`
  `git add -f ./pkg/riddl-#{pkg.version.to_s}.gem`
end

