require 'rake'
require 'rake/gempackagetask'

spec = eval(File.read('riddl.gemspec'))
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

