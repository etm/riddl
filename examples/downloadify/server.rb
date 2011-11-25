#!/usr/bin/ruby
$port = 9298
$host = 'http://localhost'
$mode = :debug # :production

if File.exists?(File.expand_path(File.dirname(__FILE__) + '/server.config.rb'))
  require File.expand_path(File.dirname(__FILE__) + '/server.config')
end  

$0    = "downloadify"
$url  = $host + ':' + $port.to_s

require 'pp'
require 'fileutils'
require 'rubygems'
require 'riddl/server'
require 'riddl/utils/downloadify'

rsrv = Riddl::Server.new(::File.dirname(__FILE__) + '/server.declaration.xml',File.expand_path(::File.dirname(__FILE__))) do
  accessible_description true
  cross_site_xhr true

  on resource do
    run Riddl::Utils::Downloadify if get
  end
end

########################################################################################################################
# parse arguments
########################################################################################################################
verbose = false
operation = "start"
ARGV.options { |opt|
  opt.summary_indent = ' ' * 4
  opt.banner = "Usage:\n#{opt.summary_indent}ruby server.rb [options] start|startclean|stop|restart|info\n"
  opt.on("Options:")
  opt.on("--verbose", "-v", "Do not daemonize. Write ouput to console.") { verbose = true }
  opt.on("--help", "-h", "This text.") { puts opt; exit }
  opt.separator(opt.summary_indent + "start|stop|restart|info".ljust(opt.summary_width+1) + "Do operation start, stop, restart or get information.")
  opt.separator(opt.summary_indent + "startclean".ljust(opt.summary_width+1) + "Delete all instances before starting.")
  opt.parse!
}
unless %w{start startclean stop restart info}.include?(ARGV[0])
  puts ARGV.options
  exit
end
operation = ARGV[0]

########################################################################################################################
# status and info
########################################################################################################################
pid = File.read('server.pid') rescue pid = 666
status = `ps -u #{Process.uid} | grep "#{pid} "`.scan(/ server\.[^\s]+/)
if operation == "info" && status.empty?
  puts "Server (#{$url}) not running"
  exit
end
if operation == "info" && !status.empty?
  puts "Server (#{$url}) running as #{pid}"
  stats = `ps -o "vsz,rss,lstart,time" -p #{pid}`.split("\n")[1].strip.split(/ +/)
  puts "Virtual:  #{"%0.2f" % (stats[0].to_f/1024)} MiB"
  puts "Resident: #{"%0.2f" % (stats[1].to_f/1024)} MiB"
  puts "Started:  #{stats[2..-2].join(' ')}"
  puts "CPU Time: #{stats.last}"
  exit
end
if %w{start startclean}.include?(operation) && !status.empty?
  puts "Server (#{$url}) already started"
  exit
end

########################################################################################################################
# stop/restart server
########################################################################################################################
if %w{stop restart}.include?(operation)
  if status.empty?
    puts "Server (#{$url}) maybe not started?"
  else
    puts "Server (#{$url}) stopped"
    `kill #{pid}`
    puts "Waiting for 2 seconds to accomplish ..."
    sleep 2 if operation == "restart"
  end
  exit unless operation == "restart"
end

########################################################################################################################
# start server
########################################################################################################################
if operation == 'startclean'
  Dir.glob(File.expand_path(File.dirname(__FILE__) + '/instances/*')).each do |d|
    FileUtils.rm_r(d) if File.basename(d) =~ /^\d+$/
  end
end

server = if verbose
  Rack::Server.new(
    :app => rsrv,
    :Port => $port,
    :environment => ($mode == :debug ? 'development' : 'deployment'),
    :server => 'mongrel',
    :pid => File.expand_path(File.dirname(__FILE__) + '/server.pid')
  )
else
  server = Rack::Server.new(
    :app => rsrv,
    :Port => $port,
    :environment => 'none',
    :server => 'mongrel',
    :pid => File.expand_path(File.dirname(__FILE__) + '/server.pid'),
    :daemonize => true
  )
end

puts "Server (#{$url}) started"
server.start
