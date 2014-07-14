require 'rubygems'
require 'rdf/smart'
require 'json'

module Riddl
  module Utils

    module Turtle
      
      class File
        attr_accessor :data, :changed
        attr_reader :url

        def initialize(url)
          @url = url
          @data = ""
          @changed = Time.at(0)
        end
      end  

      def self::implementation(tf)
        Proc.new do
          if ::File.mtime(tf.url) > tf.changed
            tf.data = ""
            ::File.open(tf.url,"r") do |f|
              f.each_line do |line|
                tf.data += line
              end
            end
            tf.changed = ::File.mtime(tf.url)
          end
          run Show, tf.data, tf.changed if get
          run Query, tf.url if get 'query'
          on resource do
            run GetQuery, tf.url if get 
          end
        end
      end
      class Query < Riddl::Implementation # {{{
          def response #{{{
            Riddl::Parameter::Complex.new "list","application/json", JSON::pretty_generate(RDF::Smart.new(@a[0]).execute(@p[0].value))
          end #}}}
      end  # }}}
      class Show < Riddl::Implementation # {{{
          def response #{{{
              Riddl::Parameter::Complex.new "list", "text/plain", @a[0]
          end #}}}
      end # }}}
      class GetQuery < Riddl::Implementation#{{{
        def response #{{{
          a = RDF::Smart.new(@a[0])
          if a.namespaces.size > 0
            ns = ""
            if @r[-1].start_with?(":")
              if (!(a.namespaces[nil]))
                return Riddl::Parameter::Complex.new "value","text/plain", "Error parsing namespaces"
              end
              return Riddl::Parameter::Complex.new "value","application/json", JSON::pretty_generate(a.execute("PREFIX : <" + a.namespaces[nil] + "> SELECT * WHERE { #{@r[-1]} ?p ?o}"))
            else
              if (!(a.namespaces[@r[-1].partition(":")[0]]))
                return Riddl::Parameter::Complex.new "value","text/plain", "Error parsing namespaces"
              end
              return Riddl::Parameter::Complex.new "value","application/json", JSON::pretty_generate(a.execute("PREFIX #{@r[-1].partition(":")[0]}: <" + a.namespaces[@r[-1].partition(":")[0]] + "> SELECT * WHERE { #{@r[-1]} ?p ?o}"))
            end 
          end
          Riddl::Parameter::Complex.new "list","application/json", JSON::pretty_generate(a.execute("select * where {#{@r[-1]} ?p ?o}"))
        end #}}}
      end#}}}
  
    end
  end
end
