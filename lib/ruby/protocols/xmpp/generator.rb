require File.expand_path(File.dirname(__FILE__) + '/../../constants')

module Riddl
  module Protocols
    module XMPP
      class Generator
        XR_NS = 'http://www.fp7-adventure.eu/ns/xmpp-rest/'.freeze
        
        class Stanza < Blather::Stanza
          def self.new
            node = super :message
            node.type = :normal
            node.id = SecureRandom.uuid
            node
          end  
        end

        def initialize(method,headers,params)
          @params = params
          @stanza = Stanza.new
          @node = XML::Smart::Dom::Element.new(@stanza)
          @node.add('operation',method).namespaces.add(nil,XR_NS)
          headers.each do |k,v|
            @node.add('header',v,:name => k).namespaces.add(nil,XR_NS)
          end
        end

        # Performs URI escaping so that you can construct proper
        # query strings faster.  Use this rather than the cgi.rb
        # version since it's faster. (%20 instead of + for improved standards conformance).
        def self.escape(s)
          s.to_s.gsub(/([^a-zA-Z0-9_.-]+)/n) {
            '%'+$1.unpack('H2'*$1.size).join('%').upcase
          }
        end

        def generate(mode=:output)
          if @params.is_a?(Array) && @params.length == 1
            body(@params[0],mode)
          elsif @params.class == Riddl::Parameter::Simple || @params.class == Riddl::Parameter::Complex
            body(@params,mode)
          elsif @params.is_a?(Array) && @params.length > 1
            multipart(mode)
          else
            @stanza
          end  
        end

        def body(r,mode)
          case r
            when Riddl::Parameter::Simple
              if mode == :output
                n = @node.add('part',r.value)
                n.namespaces.add(nil,XR_NS)
                n.attributes['content-type'] = 'text/plain'
                n.attributes['content-id'] = r.name
                n.attributes['RIDDL-TYPE'] = 'simple'
              end
              if mode == :input
                n = @node.add('part')
                n.namespaces.add(nil,XR_NS)
                n.attributes['content-type'] = 'application/x-www-form-urlencoded'
                n.text = self.class::escape(r.name) + '=' + self.class::escape(r.value)
              end
            when Riddl::Parameter::Complex
              n = @node.add('part')
              n.namespaces.add(nil,XR_NS)
              n.text = (r.value.respond_to?(:read) ? r.value.read : r.value)
              n.attributes['content-type'] = r.mimetype
              n.attributes['RIDDL-TYPE'] = 'complex'
              if r.filename.nil?
                n.attributes['content-id'] = r.name
              else
                n.attributes['content-disposition'] = "riddl-data; name=\"#{r.name}\"; filename=\"#{r.filename}\""
              end  
          end
          @stanza
        end
        private :body

        def multipart(mode)
          scount = ccount = 0
          @params.each do |r|
            case r
              when Riddl::Parameter::Simple
                scount += 1
              when Riddl::Parameter::Complex
                ccount += 1
            end   
          end
          if scount > 0 && ccount == 0
            n = @node.add('part')
            n.namespaces.add(nil,XR_NS)
            n.attributes['content-type'] = 'application/x-www-form-urlencoded'
            res = []
            @params.each do |r|
              case r
                when Riddl::Parameter::Simple
                  res << self.class::escape(r.name) + '=' + self.class::escape(r.value)
              end   
            end
            n.text = res.join('&')
          else
            if scount + ccount > 0
              @node.add('header',scount+ccount,:name => 'RIDDL-MULTIPART').namespaces.add(nil,XR_NS)
              @params.each do |r|
                case r
                  when Riddl::Parameter::Simple
                    n = @node.add('part')
                    n.namespaces.add(nil,XR_NS)
                    n.attributes['RIDDL-TYPE'] = 'simple'
                    n.attributes['content-disposition'] = "#{mode == :input ? 'form-data' : 'riddl-data'}; name=\"#{r.name}\""
                    n.text = r.value
                  when Riddl::Parameter::Complex
                    n = @node.add('part')
                    n.namespaces.add(nil,XR_NS)
                    n.attributes['RIDDL-TYPE'] = 'complex'
                    n.attributes['content-disposition'] = "#{mode == :input ? 'form-data' : 'riddl-data'}; name=\"#{r.name}\"#{r.filename.nil? ? '' : "; filename=\"#{r.filename}\""}"
                    n.attributes['content-transfer-encoding'] = 'binary'
                    n.attributes['content-type'] = r.mimetype
                    n.text = (r.value.respond_to?(:read) ? r.value.read : r.value)
                end   
              end
            end
          end
          @stanza
        end
        private :multipart
      
      end
    end
  end
end  
