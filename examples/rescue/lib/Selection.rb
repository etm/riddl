require '../../lib/ruby/client'
class SelectByRandom < Riddl::Implementation
  def response
    # {{{
      puts "==SelectByRandom=="*5
      group_by = @p.value('group_by')
      puts "=== GROUP_BY: #{group_by}"
      uri_xpath = @p.value('uri_xpath')
      puts "=== URI-XPATH: #{uri_xpath}"
      target_endpoint = @p.value('target_endpoint')
      puts "=== TARGET_EP: #{target_endpoint}"
      data = XML::Smart.string(@p.value('data'))
      elements = data.find(group_by)
      num = rand(elements.length)
      show = elements[num]
      puts "=== SELECTED SHOW:"
      puts show.dump
      title = ""
      show_id = ""
      starting_time =""
      hall = ""
      show.children.each do |e| 
        title = e.text if e.name.name == "title" 
        show_id = e.text if e.name.name == "show_id" 
        starting_time = e.text if e.name.name == "starting_time"
        hall = e.text if e.name.name == "hall" 
      end
      puts "=== Title: #{title}"
      puts "=== Show-Id: #{show_id}"
      puts "=== Starting Time: #{starting_time}"
      puts "==SelectByRandom=="*5
      [Riddl::Parameter::Simple.new("title", title),
       Riddl::Parameter::Simple.new("hall", hall),
       Riddl::Parameter::Simple.new("show_id", show_id),
       Riddl::Parameter::Simple.new("starting_time", starting_time)]
    # }}}
  end
end
