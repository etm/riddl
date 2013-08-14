require File.expand_path(File.dirname(__FILE__) + '/../../constants')
require File.expand_path(File.dirname(__FILE__) + '/../../parameter')

module Riddl
  module Protocols
    module XMPP
      class Parser
        FORM_CONTENT_TYPES = [
          #{{{
          nil,
          'application/x-www-form-urlencoded'
          #}}}
        ].freeze

        STD_ATTRIBUTES = [
          #{{{
          'content-type',
          'content-disposition',
          'content-id',
          'content-transfer-type',
          'RIDDL-TYPE',
          #}}}
        ].freeze

        def self::unescape(s)
          #{{{
          return s if s.nil?  
          s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
            [$1.delete('%')].pack('H*')
          }
          #}}}
        end

        def parse_part(input,head,ctype,content_disposition,content_id,riddl_type)
 #{{{
          head = Hash[
            head.map do |h|
              STD_ATTRIBUTES.include?(h.qname.name) ? nil : [h.qname.name, value]
            end.compact
          ]
          ctype = nil if riddl_type == 'simple'
          filename = content_disposition[/ filename="?([^\";]*)"?/ni, 1]
          name = content_disposition[/ name="?([^\";]*)"?/ni, 1] || content_id

          if ctype || filename
            body = Parameter::Tempfile.new("RiddlMultipart")
            body.binmode if body.respond_to?(:binmode)
          else
            body = ''
          end

          input.each { |i| body << i.dump }
          body.rewind # if body.respond_to?(:binmode)

          add_to_params(name,body,filename,ctype,head)
 #}}}
        end

        def add_to_params(name,body,filename,ctype,head)
          #{{{
          if filename == ""
            # filename is blank which means no file has been selected
          elsif filename && ctype
            body.rewind

            # Take the basename of the upload's original filename.
            # This handles the full Windows paths given by Internet Explorer
            # (and perhaps other broken user agents) without affecting
            # those which give the lone filename.
            filename =~ /^(?:.*[:\\\/])?(.*)/m
            filename = $1

            @params << Parameter::Complex.new(name, ctype, body, filename, head)
          elsif !filename && ctype
            body.rewind
            
            # Generic multipart cases, not coming from a form
            @params << Parameter::Complex.new(name, ctype, body, nil, head)
          else
            @params << Parameter::Simple.new(name, body, :body)
          end
          #}}}
        end
        private :add_to_params

        def parse_nested_query(qs, type)
          #{{{
          (qs || '').split(/[#{D}] */n).each do |p|
            k, v = self.class::unescape(p).split('=', 2)
            @params << Parameter::Simple.new(k,v,type)
          end
          #}}}
        end
        private :parse_nested_query

        def initialize(query_string,input)
          #{{{
          @params = Riddl::Parameter::Array.new

          parse_nested_query(query_string,:query)

          input.find('/message/xr:part').each do |p|
            content_type = p.attributes['content-type'] || ''
            media_type = content_type && content_type.split(/\s*[;,]\s*/, 2).first.downcase
            if FORM_CONTENT_TYPES.include?(media_type)
              # sub is a fix for Safari Ajax postings that always append \0
              parse_nested_query(p.text.sub(/\0\z/, ''),:body)
            else  
              parse_part(p.children,p.attributes,content_type,p.attributes['content_disposition']||'',p.attributes['content-id']||'',p.attributes['RIDDL-TYPE']||'')
            end
          end
          #}}}
        end

        attr_reader :params
      end
    end
  end
end  
