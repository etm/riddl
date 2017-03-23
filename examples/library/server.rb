#!/usr/bin/ruby
require 'pp'
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/server')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby/riddl/utils/erbserve')

class BookQuery < Riddl::Implementation
  def response
    authors = @p.map{|e|e.name == "author" ?  "<author>" + e.value + "</author>" : nil }.compact
    title = @p.map{|e|e.name == "title" ?  e.value : nil }.compact.join
    Riddl::Parameter::Complex.new("list-of-books","text/xml") do
      <<-END
        <books>
          <book id="1">
            <title>#{title}</title>
            <author>Agador</author>
            #{authors.join}
          </book>
        </books>
      END
    end
  end
end

class BookDescription < Riddl::Implementation
  def response
    Riddl::Parameter::Complex.new("book-description","text/xml") do
      <<-END
        <book id="1">
          <title>The Book</title>
          <author>Agador</author>
        </book>
      END
    end
  end
end

Riddl::Server.new(File.dirname(__FILE__) + '/description.xml', :port => 9292, :bind => '::') do
  accessible_description true

  on resource do
    run Riddl::Utils::ERBServe, "static/info.txt"  if get
    on resource "books" do
      run BookQuery if get 'book-query'
      on resource '\d+' do
        run BookDescription if get
      end
    end
    on resource "about" do
      run Riddl::Utils::ERBServe, "static/info.txt"  if get
    end
  end
end.loop!
