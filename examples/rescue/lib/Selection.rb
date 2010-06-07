require '../../lib/ruby/client'
class SelectByRandom < Riddl::Implementation
  def response
    # {{{
      puts "==SelectByRandom=="*5
      group_by = @p.value('group_by')
      puts "=== GROUP_BY: #{group_by}"
      uri_xpath = @p.value('uri_xpath')
      puts "=== URI-XPATH: #{uri_xpath}"
      data = XML::Smart.string(@p.value('data'))
      elements = data.find(group_by)
      num = rand(elements.length)
      show = elements[num]
      puts "=== SELECTED SHOW:"
      puts show.dump
      title = "n.a."
      show_id = "n.a."
      starting_time ="n.a."
      hall = "n.a."
      show.children.each do |e| 
        title = e.text if e.name.name == "title" 
        show_id = e.text if e.name.name == "show_id" 
        starting_time = e.text if e.name.name == "time"
        hall = e.text if e.name.name == "hall" 
      end
      puts "=== Title: #{title}"
      puts "=== Hall: #{hall}"
      puts "=== Show-Id: #{show_id}"
      puts "=== Starting Time: #{starting_time}"
      puts "=== URI: #{show.find(uri_xpath).first.text}"
      puts "==SelectByRandom=="*5
      [Riddl::Parameter::Simple.new("movie_title", title),
       Riddl::Parameter::Simple.new("hall", hall),
       Riddl::Parameter::Simple.new("show_id", show_id),
       Riddl::Parameter::Simple.new("starting_time", starting_time),
       Riddl::Parameter::Simple.new("target", show.find(uri_xpath).first.text)]
    # }}}
  end
end
