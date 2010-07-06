require '../../lib/ruby/client'
$selection_data = Hash.new

class SelectByRandom < Riddl::Implementation
  def response
    # {{{
      puts "==SelectByRandom=="*5
      data = XML::Smart.string(@p.value('data'))
      puts "=== LIST:\n #{data}"
      group_by = @p.value('group_by')
      puts "=== GROUP_BY: #{group_by}"
      uri_xpath = @p.value('uri_xpath')
      puts "=== URI-XPATH: #{uri_xpath}"
      elements = data.find(group_by)
      num = rand(elements.length)
      show = elements[num]
      puts "=== SELECTED SHOW:"
      puts show.dump
      title = "n.a."
      show_id = "n.a."
      starting_time ="n.a."
      hall = "n.a."
      date = "Error in parsing"
      show.children.each do |e| 
        title = e.text if e.name.name == "title" 
        show_id = e.text if e.name.name == "show_id" 
        starting_time = e.text if e.name.name == "time"
        date = e.text if e.name.name == "date"
        hall = e.text if e.name.name == "hall" 
      end
      puts "=== Title: #{title}"
      puts "=== Hall: #{hall}"
      puts "=== Show-Id: #{show_id}"
      puts "=== Starting Time: #{starting_time}"
      puts "=== URI: #{show.find(uri_xpath).first.text}"
      puts "==SelectByRandom=="*5
      [Riddl::Parameter::Simple.new("show_id", show_id),
       Riddl::Parameter::Simple.new("target", show.find(uri_xpath).first.text),
       Riddl::Parameter::Simple.new("movie_title", title),
       Riddl::Parameter::Simple.new("starting_time", starting_time),
       Riddl::Parameter::Simple.new("date", date),
       Riddl::Parameter::Simple.new("hall", hall)]
    # }}}
  end
end

class PostSelectByUser < Riddl::Implementation
  def response
    # {{{
      data = XML::Smart.string(@p.value('data'))
    # }}}
  end
end

class GetSelectionData < Riddl::Implementation
  def response
  end
end
