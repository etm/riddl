require File.expand_path(File.dirname(__FILE__) + '/../../constants')
require 'blather/client/client'
require 'securerandom'

module Riddl
  module Protocols
    module XMPP
      XR_NS = 'http://riddl.org/ns/xmpp-rest'.freeze

      class Stanza < Blather::Stanza
        def self.new
          node = super :message
          node.type = :normal
          node.id = SecureRandom.uuid
          node
        end
      end

      class Error
        MAPPING = {
          302 => ['redirect'                , 'modify' , '302 Redirect'              ],
          400 => ['bad-request'             , 'modify' , '400 Bad Request'           ],
          401 => ['not-authorized'          , 'auth'   , '401 Not Authorized '       ],
          402 => ['payment-required'        , 'auth'   , '402 Payment Required'      ],
          403 => ['forbidden'               , 'auth'   , '403 Forbidden'             ],
          404 => ['item-not-found'          , 'cancel' , '404 Not Found'             ],
          405 => ['not-allowed'             , 'cancel' , '405 Not Allowed'           ],
          406 => ['not-acceptable'          , 'modify' , '406 Not Acceptable'        ],
          407 => ['registration-required'   , 'auth'   , '407 Registration Required' ],
          408 => ['remote-server-timeout'   , 'wait'   , '408 Request Timeout'       ],
          409 => ['conflict'                , 'cancel' , '409 Conflict'              ],
          500 => ['internal-server-error'   , 'wait'   , '500 Internal Server Error' ],
          501 => ['feature-not-implemented' , 'cancel' , '501 Not Implemented'       ],
          502 => ['service-unavailable'     , 'wait'   , '502 Remote Server Error'   ],
          503 => ['service-unavailable'     , 'cancel' , '503 Service Unavailable'   ],
          504 => ['remote-server-timeout'   , 'wait'   , '504 Remote Server Timeout' ],
          510 => ['service-unavailable'     , 'cancel' , '510 Disconnected'          ]
        }.freeze
        UNDEFINED = [
          'undefined-condition', 'modify'
        ].freeze

        def initialize(err)
          m = Stanza.new
          @stanza = if MAPPING[err]
            Blather::StanzaError.new(m,*MAPPING[err]).to_node
          else
            Blather::StanzaError.new(m,*UNDEFINED,'#{err} see http://www.iana.org/assignments/http-status-codes/http-status-codes.xml').to_node
          end
        end

        def generate
          @stanza
        end
      end

      class Generator
        def initialize(what,params,headers,ack=false)
          @params = params
          @stanza = Stanza.new
          @node = XML::Smart::Dom::Element.new(@stanza)
          if what.is_a?(Fixnum)
            @node.add('ok').namespaces.add(nil,XR_NS)
          else
            @node.add('operation',what,:ack=>ack).namespaces.add(nil,XR_NS)
          end
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
