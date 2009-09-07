require ::File.dirname(__FILE__) + '/description'
require ::File.dirname(__FILE__) + '/declaration/tile'
require ::File.dirname(__FILE__) + '/declaration/facade'

module Riddl
  class File
    class Declaration

      def description_xml
        #{{{
        @fac.generate_description_xml
        #}}}
      end

      def visualize_tree_and_layers
        #{{{
        @tiles.each_with_index do |til,index|
          puts "### Tile #{index} " + ("#" * 60)
          til.visualize :layers
        end
        #}}}
      end

      def visualize_tree_and_facade
        #{{{
        @tiles.each_with_index do |til,index|
          puts "### Tile #{index} " + ("#" * 60)
          til.visualize :facade
        end
        #}}}
      end

      def merge_tiles(res)
        #pp res.path
        #pp res.resources
      end
      private :merge_tiles

      def initialize(riddl)
        #{{
        ### create single tiles
        @tiles = []
        riddl.find("/dec:declaration/dec:facade/dec:tile").each do |tile|
          @tiles << (til = Tile.new)
          res = til.base_path(tile.attributes['path'] || '/')
          # res.clean! # for overlapping tiles, each tile gets an empty path TODO
          tile.find("dec:layer").each_with_index do |layer,index|
            apply_to = layer.find("dec:apply-to")
            block = layer.find("dec:block")

            lname = layer.attributes['name']
            des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
            desres = des.find("des:resource").first
            if apply_to.empty?
              til.add_description(des,desres,"/",index,block)
            else
              apply_to.each do |at|
                til.add_description(des,desres,at.to_s,index,block)
              end
            end
          end
          til.compose!
        end

        ### merge tiles into a facade
        @fac = Facade.new
        @tiles.each do |til|
          merge_tiles(til.resource)
        end
        #}}}
      end
    end
  end
end
