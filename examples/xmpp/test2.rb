# encoding: UTF-8
require 'rubygems'
require 'securerandom'
require 'blather/client/dsl'
require 'pp'

class RESTMessage < Blather::Stanza

  class Headers < Hash #{{{
    def initialize(he,message)
      @headers = Hash[*he]
      @message = message
    end  

    def [](hname)
      @headers[hname]
    end

    def []=(hname,value)
      if hname
        if elem = @message.find_first("ns:header[@name='#{hname}']", :ns => @message.class::XR_HEADER_NS)
          elem[hname] = value
        else
          he = Blather::XMPPNode.new('header', @message.document)
          he.namespace = @message.class::XR_HEADER_NS
          he['name'] = hname
          he.content = value
          @message.xpath('ns1:*|ns2:*', :ns1 => @message.class::XR_OPERATION_NS, :ns2 => @message.class::XR_HEADER_NS).after(he)
        end
      end  
    end
  end #}}}

  class Parts < Hash #{{{
    def initialize(pa,message)
      @parts = Hash[*pa]
      @message = message
    end  

    def [](pname)
      @parts[hname]
    end

    def []=(pname,props)
      if pname
        if elem = @message.find_first("ns:header[@name='#{hname}']", :ns => @message.class::XR_HEADER_NS)
          elem[hname] = value
        else
          he = Blather::XMPPNode.new('header', @message.document)
          he.namespace = @message.class::XR_HEADER_NS
          he['name'] = hname
          he.content = value
          @message.xpath('ns1:*|ns2:*', :ns1 => @message.class::XR_OPERATION_NS, :ns2 => @message.class::XR_HEADER_NS).after(he)
        end
      end  
    end
  end #}}}

  VALID_OPS = [:get, :post, :put, :delete].freeze
  XR_OPERATION_NS = 'http://www.fp7-adventure.eu/ns/xmpp-rest/operation'.freeze
  XR_HEADER_NS = 'http://www.fp7-adventure.eu/ns/xmpp-rest/header'.freeze
  XR_PART_NS = 'http://www.fp7-adventure.eu/ns/xmpp-rest/part'.freeze

  def self.new(to = nil)
    node = super :message
    node.to = to
    node.type = :normal
    node.id = SecureRandom.uuid
    node.operation = :get
    node
  end

  def operation
    if (elem = find_first('ns:operation', :ns => XR_OPERATION_NS)) && VALID_OPS.include?(name = elem.name.to_sym)
      name
    end
  end

  def operation=(opname)
    if opname && !VALID_OPS.include?(opname.to_sym)
      raise ArgumentError, "Invalid Operation (#{opname}), use: #{VALID_OPS*' '}"
    end

    xpath('ns:operation', :ns => XR_OPERATION_NS).remove

    if opname
      op = Blather::XMPPNode.new('operation', self.document)
      op['type'] = opname.to_s
      op.namespace = XR_OPERATION_NS
      if self.children.empty?
        self << op
      else  
        self.children.before(op)
      end  
    end
  end

  def headers
    Headers.new xpath('ns:*', :ns => XR_HEADER_NS).map{ |ele| [ele['name'], ele.content] }.flatten, self
  end

  def parts
    Parts.new xpath('ns:*', :ns => XR_HEADER_NS).map{ |ele| [ele['id'], ele] }.flatten, self
  end

end

class AdventureIq < Blather::Stanza::Iq #{{{
  def self.new(to, type = :get)
    type = case 
      when :create, :update, :delete
        :set
      when :read
        :get
      else
        :get
    end    
    node = super type, to, SecureRandom.uuid
    node.content
    node
  end

  def content
    q = if self.class.registered_ns
      find_first('query_ns:query', :query_ns => self.class.registered_ns)
    else
      find_first('content')
    end

    unless q
      (self << (q = Blather::XMPPNode.new('content', self.document)))
      q.namespace = self.class.registered_ns
    end
    q
  end
end #}}}

module Pong
  extend Blather::DSL  

  when_ready do 
    mess = RESTMessage.new "adventure_processexecution@fp7-adventure.eu"
    mess.headers['bla'] = 7
    mess.headers['r'] = 8
    mess.operation = :post
    mess.headers['bla'] = 9
    puts mess.to_s
    #write_to_stream mess
  end
end

Pong.setup "jürgen@fp7-adventure.eu", 'mangler'
EM.run { Pong.run }
