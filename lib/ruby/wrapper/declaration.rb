require File.expand_path(File.dirname(__FILE__) + '/description')
require File.expand_path(File.dirname(__FILE__) + '/declaration/tile')
require File.expand_path(File.dirname(__FILE__) + '/declaration/facade')

module Riddl
  class Wrapper
    class Declaration < WrapperUtils
        
      def get_resource(path)
        get_resource_deep(path,@facade.resource)
      end  
      def paths
        rpaths(@facade.resource,'')
      end
      
      def description_xml
        @facade.description_xml
      end  

      def visualize_tiles_and_layers
        #{{{
        @tiles.each_with_index do |til,index|
          puts "### Tile #{index} " + ("#" * 60)
          til.visualize :layers
        end
        #}}}
      end
      def visualize_tiles_and_compositions
        #{{{
        @tiles.each_with_index do |til,index|
          puts "### Tile #{index} " + ("#" * 60)
          til.visualize :composition
        end
        #}}}
      end
      def visualize_facade(res=@facade.resource,what='')
        #{{{
          what += res.path
          puts what
          res.composition.each do |k,v|
            puts "  #{k.upcase}:"
            v.each do |r|
              puts "    #{r.result.class.name.gsub(/[^\:]+::/,'')}: #{r.result.visualize}"
              r.route.each do |ritem|
                puts "      #{ritem.class.name.gsub(/[^\:]+::/,'')}: #{ritem.visualize}"
              end unless r.route.nil?
            end
          end
          res.resources.each do |key,r|
            visualize_facade(r,what + (what == '/' ? ''  : '/'))
          end
        #}}}
      end

      def initialize(riddl)
        @facade = Riddl::Wrapper::Declaration::Facade.new
        #{{{
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
            lpath = riddl.find("string(/dec:declaration/dec:interface[@name=\"#{lname}\"]/@path)")
            des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
            desres = des.find("des:resource").first
            if apply_to.empty?
              til.add_description(des,desres,"/",index,"#{lpath}",block)
            else
              apply_to.each do |at|
                til.add_description(des,desres,at.to_s,index,"#{lpath}",block)
              end
            end
          end
          til.compose!
        end

        ### merge tiles into a facade
        @tiles.each do |til|
          @facade.merge_tiles(til.resource)
        end
        #}}}
      end

    end
  end
end
