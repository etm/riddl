#!/usr/bin/ruby
require 'git'

home = `git rev-parse --show-toplevel`.strip
log = `git log --since 2011/10/31 --until 2014/10/31 --pretty=format:"####%aN####%ct####%s" --reverse --summary --numstat --encoding=UTF-8 --no-renames`

class Details #{{{
  attr_accessor :added, :deleted, :type

  def initialize
    @type = 'modify'
    @added = 0
    @deleted = 0
  end
end #}}}

class Commit  #{{{
  attr_reader :author, :date, :subject, :files
  def initialize(author,date,subject)
    @author = author
    @date = date
    @subject = subject
    @files = {}
  end
end #}}}

commits = []
log.each_line do |l|
  if l =~ /^####(.*)####(\d+)####(.*)$/
    timestamp = Time.at($2.to_i)
    author = $1
    subject = $3
    commits << Commit.new(author,timestamp,subject)
  else
    if l.strip =~ /^(\d+)\t(\d+)\t(.*)$/
      entry = (commits.last.files[$3] ||= Details.new)
      entry.added = $1.to_i
      entry.deleted = $2.to_i
    elsif l.strip =~ /^(\w+) mode (\d+) (.*)$/
      entry = (commits.last.files[$3] ||= Details.new)
      entry.type = $1
    else 
    end
  end
end

files = []
commits.each do |c|
  c.files.each do |k,v|
    files << k
  end
end

### commits per author
authors = {}
commits.each do |c|
  authors[c.author] ||= []
  authors[c.author] << c
end

### delete files that are not on whitelist
if File.exists? "#{home}/.whitelist"
  whitelist = []
  whitelist = File.readlines("#{home}/.whitelist").map{|l| l.strip}
  commits.each do |c|
    c.files.delete_if do |k,v|
      !(whitelist.include?(k))
    end
  end
end

### stats
funique = {}
files = {}
lines = {}
ftypes = {}
authors.each do |a,c|
  lines[a] ||= {}
  files[a] ||= {}
  ftypes[a] ||= {}
  funique[a] ||= []
  c.each do |comm|
    comm.files.each do |fname,details|
      lines[a]['added'] ||= 0
      lines[a]['added'] += details.added
      lines[a]['deleted'] ||= 0
      lines[a]['deleted'] += details.deleted
      fname =~ /\.([a-zA-Z0-9]*)$/
      ftype = $1||'---'
      ftypes[a][ftype] ||= [0,0,0]
      ftypes[a][ftype][1] += details.added
      ftypes[a][ftype][2] += details.deleted
      unless funique[a].include?(fname)
        ftypes[a][ftype][0] += 1
        files[a]['unique'] ||= 0
        files[a]['unique'] += 1
        funique[a] << fname
      end
      files[a][details.type] ||= 0
      files[a][details.type] += 1
    end
  end
end

statstxt = ""
authors.each do |a,c|
  statstxt << "#{a} (#{c.length} commits)\n"
  lines[a].each do |k,v|
    statstxt << "    Lines #{k}:\t#{v}\n"
  end
  files[a].each do |k,v|
    statstxt << "    Files #{k}:\t#{v}\n"
  end
  statstxt << "    By File Type:\n"
  ftypes[a].each do |k,v|
    statstxt << "        '#{k}':\t#{v[0]} unique,\t#{v[1]} lines added,\t#{v[2]} lines deleted\n"
  end
end

File.write("#{home}/.stats",statstxt)

### print all files in repo
# files.uniq.sort.each do |f|
#   puts f
# end

### print list of files/commit
# commits.each do |c|
#   c.files.each do |k,v|
#     puts "#{c.author}\t#{c.date.to_i}\t#{c.subject}\t#{v.type}\t#{v.added}\t#{v.deleted}\t#{k}"
#   end
# end
