require '../../lib/ruby/client.rb'
require 'rubygems'
require 'xml/smart'
require 'cgi'

      title = "Prince"
      date = Date.parse("2010-06-18")

      endpoint = "http://www.cineplexx.at/content/kinos/kinoprogramm.aspx"
      client = Riddl::Client.new(endpoint)
      status, resp = client.get [
        Riddl::Parameter::Simple.new("id", 1, :query), 
        Riddl::Parameter::Simple.new("datum", "18.06.2010", :query), 
        Riddl::Parameter::Simple.new("uhrzeit","00:00:00", :query), 
        Riddl::Parameter::Simple.new("version","",:query)
      ]
      puts status
      puts resp.inspect
      str = CGI::unescapeHTML(resp.value('').read)
#      puts str
      response = str
      offset = str.index("uclKinoprogramm$DDL_Datum")
      offset = str.index("selected=\"selected\"", offset)
      puts str[offset..offset+200]
      offset = str.index("value=\"", offset)
      d = str[offset+7..offset+16]
      puts "Date: #{d}"

      str = str[str.index("<div id=\"uclKinoprogramm_P_Filme\">")..-1]
      count = 1
      offset = 0
      while (count != 0) do
        offset = str.index("div", offset+1)
        count = count+1 if str[offset-1].chr == "<"
        count = count-1 if str[offset-1].chr == "/"
      end
      str = str[0..offset-3]
      str.gsub!('&', '&amp;')
      resp = XML::Smart.string(str)
          list = XML::Smart.string("<list_of_shows/>")
          resp.find("//table[descendant::td/a[contains(text(),'#{title}')]]").each do |b| 
            show_title = b.find("child::tr/td[1]/a").first.text.strip
            puts "Title: #{show_title}"
# Check if date is right?
            show_date = Date.parse(d)
            if show_date == date
              line = 1
              b.find("child::tr/td[3]/div/table").each do |show|
                show_hall = show.find("child::tr/td[1]/h4/span").first.text.strip
                puts "Hall: #{show_hall}"
                show.find("child::tr/td[2]/span/a[text()]").each do |s|
                  show = list.root.add("show")
                  show.add("cinema_uri", "http://localhost:9290/groups/CinemasReal/REST/AugeGottes")
                  show.add("show_id", s.attributes['href'])
                  show.add("title", show_title)
                  show.add("hall", show_hall)
                  show.add("time", s.text)
                  show.add("date", show_date.to_s)
                end
                line = line+1
              end
            end
          end
          puts "#{CGI::unescapeHTML(list.root.dump)}"
