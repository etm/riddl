require File.expand_path(File.dirname(__FILE__) + '/description')
require File.expand_path(File.dirname(__FILE__) + '/declaration/tile')
require File.expand_path(File.dirname(__FILE__) + '/declaration/facade')
require File.expand_path(File.dirname(__FILE__) + '/declaration/interface')

module Riddl
  class Wrapper
    class Declaration < WrapperUtils

      def get_resource(path)
        get_resource_deep(path,@facade.resource)
      end
      def paths
        rpaths(@facade.resource)
      end

      def description_xml
        @facade.description_xml(@namespaces)
      end

      def description
        Riddl::Wrapper.new(@facade.description_xml(@namespaces))
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
            puts "  #{k.to_s.upcase}:"
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
        @namespaces = riddl.namespaces
        #{{{
        ### create single tiles
        @tiles = []
        @interfaces = {}
        riddl.find("/dec:declaration/dec:interface").each do |int|
          @interfaces[int.attributes['name']] = [int.attributes['location'],int.find("des:description").first]
        end
        riddl.find("/dec:declaration/dec:facade/dec:tile").each do |tile|
          @tiles << (til = Tile.new)
          til.base_path(tile.attributes['path'] || '/')
          # ^ above.clean! # for overlapping tiles, each tile gets an empty path TODO
          later = []
          tile.find("dec:layer").each_with_index do |layer,index|
            apply_to = layer.find("dec:apply-to")
            block = layer.find("dec:block")

            lname = layer.attributes['name']
            lpath, des = @interfaces[lname]
            desres = des.find("des:resource").first
            if apply_to.empty?
              int = Interface.new(lname,"/",lpath,"/",des)
              rec = desres.attributes['recursive']
              til.add_description(des,desres,"/",index,int,block,rec)
            else
              apply_to.each do |at|
                t = at.to_s.sub(/^\/*/,'').split(/(?<!\*\*)\//)
                if t.last == "**/*" || t.last == "*"
                  later << [des,desres,lname,lpath,at.to_s.strip,index,block,t.last == "**/*" ? :descendants : :children]
                else
                  int = Interface.new(lname,at.to_s,lpath,"/",des)
                  til.add_description(des,desres,at.to_s,index,int,block)
                end
              end
            end
          end
          paths = @tiles.map do |ttil| # extract all currently existing paths for all tiles
            rpaths(ttil.resource).map{|a,b| a}
          end.flatten.uniq
          later.each do |lat|
            mpath = lat[4].gsub(/\/\*\*\/\*$/,'').gsub(/\/\*$/,'')
            paths.each do |path|
              pbefore, pafter = path[0..mpath.length].chop, path[mpath.length+1..-1]
              if mpath == pbefore
                if (lat[7] == :descendants && pafter != '') || (lat[7] == :children && !pafter.nil? && pafter != '' && pafter !~ /\//)
                  int = Interface.new(lat[2],path,lat[3],"/",lat[1])
                  til.add_description(lat[0],lat[1],path,lat[5],int,lat[6])
                end
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
