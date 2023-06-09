module Riddl
  class Wrapper
    class LayerChecker
      def initialize(doc)
        @doc = doc
      end

      def check
        check_layers(@doc.find("/dec:declaration/dec:facade/dec:tile/dec:layer"))
      end

      def check_layers(res)
        #{{{
        messages = []
        res.each do |tres|
          messages += check_field(tres.attributes['name'],tres.parent.attributes['relative'] || '/')
        end
        messages
        #}}}
      end
      private :check_layers

      def check_field(name,tile)
        #{{{
        if @doc.find("/dec:declaration/dec:interface[@name='#{name}']").empty?
          ["Tile '#{tile}': interface '#{name}' not found."]
        end || []
        #}}}
      end
      private :check_field
    end
  end
end
