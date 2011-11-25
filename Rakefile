require 'rake'
require 'rake/gempackagetask'

spec = eval(File.read('riddl.gemspec'))
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
  `ln -sf riddl-#{pkg.version.to_s}.gem pkg/riddl.gem`
end

