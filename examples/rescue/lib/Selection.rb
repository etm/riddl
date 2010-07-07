require '../../lib/ruby/client'
$selection_data = Hash.new

class SelectByRandom < Riddl::Implementation # {{{
  def response
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
  end
end # }}}

class PostSelectByUser < Riddl::Implementation # {{{
  def response
      instance = @p.value('call-instance-uri')
      activity = @p.value('call-activity')
      $selection_data[instance] = Hash.new unless $selection_data.include?(instance)
      $selection_data[instance][activity] = Hash.new unless $selection_data[instance].include?(activity)
      $selection_data[instance][activity]['data'] = XML::Smart.string(@p.value('data')) unless @p.value('data').nil?
      $selection_data[instance][activity]['oid'] = @p.value('call-oid')
      $selection_data[instance][activity]['callback-id'] = @h['CPEE_CALLBACK']
      $selection_data[instance][activity]['templates-uri'] = @p.value('templates-uri')
      @headers << Riddl::Header.new("CPEE-Callback",'true')
  end
end # }}}

class GetSelectionData < Riddl::Implementation # {{{
  def response
    if @p.length == 0
      inputs = XML::Smart.string('<queued-inputs/>')
      $selection_data.each do |instance, v|
        inst = inputs.root.add('instance', {'uri' => instance})
        $selection_data[instance].each do |activity, data|
          act = inst.add(activity)
          data.each {|k,v| act.add(k,v)}
        end
      end
      Riddl::Parameter::Complex.new('data', 'text/xml', inputs.to_s)
    elsif @p.value('instance') && @p.value('activity') && @p.value('name') && @p.value('lang')
      unless $selection_data.include?(@p.value('instance')) && $selection_data[@p.value('instance')].include?(@p.value('activity'))
        @status = 404
        return
      end
      status, resp = Riddl::Client.new($selection_data[@p.value('instance')][@p.value('activity')]['templates-uri']).get
      tpls = XML::Smart.string(resp[0].value.read)
      xslt = tpls.find("//xslt[@name='#{@p.value('name')}' and @xml:lang='#{@p.value('lang')}']/*").first
      if xslt.nil?
        @status = 400
        return
      end
      $selection_data[@p.value('instance')][@p.value('activity')].each do |name, value|
        xslt.add('variable', {'name' => name, 'select'=>"'#{value}'"}) unless name == 'data'
      end
      xslt.add('variable', {'name' => 'instance-uri', 'select'=>"'#{@p.value('instance')}'"})
      xslt.add('variable', {'name' => 'activity', 'select'=>"'#{@p.value('activity')}'"})
      resp = $selection_data[@p.value('instance')][@p.value('activity')]['data'].transform_with(xslt.to_doc)
      Riddl::Parameter::Complex.new('templates', 'text/html', resp.to_s)
    else
      @status = 404
      p @p
    end
  end
end # }}}
