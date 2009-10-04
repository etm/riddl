require ::File.expand_path(::File.dirname(__FILE__) + '/description')
require ::File.expand_path(::File.dirname(__FILE__) + '/declaration/tile')
require ::File.expand_path(::File.dirname(__FILE__) + '/declaration/facade')

module Riddl
  class File
    class Declaration
        
      def description_xml
        #{{{
        result = ""
        messages = {}
        names = []
        messages_result = ""
        description_xml_priv(result,messages,0)
        messages.each do |hash,mess|
          t = mess.content.dup
          name = mess.name
          name += '_' while names.include?(name)
          t.root.attributes['name'] = name
          messages_result << t.root.dump + "\n"
        end
        "<description #{Riddl::File::COMMON}>\n\n" +  messages_result.gsub(/^/,'  ') + "\n" + result + "\n</description>"
        #}}}
      end
      def description_xml_priv(result,messages,level,res=@fac)
        #{{{
        s = "  " * (level + 1)
        t = "  " * (level + 2)
        result << s + "<resource#{res.path != '/' && res.path != '' ? " relative=\"#{res.path}\"" : ''}>\n"
        res.composition.each do |k,v|
          v.each do |m|
            m = m.result
            if %w{get post put delete}.include?(k)
              result << t + "<#{k} "
            else
              result << t + "<request method=\"#.upcase{k}\" "
            end  
            case m
              when Riddl::File::Description::RequestInOut
                result << "in=\"#{m.in.name}\""
                messages[m.in.hash] = m.in
                unless m.out.nil?
                  result << " out=\"#{m.out.name}\""
                  messages[m.out.hash] = m.out
                end  
              when Riddl::File::Description::RequestStarOut
                result << "in=\"*\""
                unless m.out.nil?
                  result << " out=\"#{m.out.name}\""
                  messages[m.out.hash] = m.out
                end  
              when Riddl::File::Description::RequestPass
                result << "pass=\"#{m.pass.name}\""
                messages[m.pass.hash] = m.pass
              when Riddl::File::Description::RequestTransformation
                result << "transformation=\"#{m.trans.name}\""
                messages[m.trans.hash] = m.trans
            end  
            result << "/>\n"
          end  
        end
        res.resources.each do |k,v|
          description_xml_priv(result,messages,level+1,v)
        end
        ""
        result << s + "</resource>\n"
        #}}}
      end
      private :description_xml_priv

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
      def visualize_facade(res=@fac,what='')
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

      def merge_tiles(res,fac=@fac)
        #{{{
        res.composition.each do |method,s|
          fac.composition[method] ||= []
          fac.composition[method] += s
        end  
        res.resources.each do |path,r|
          unless fac.resources.has_key?(path)
            fac.resources[path] = Riddl::File::Description::Resource.new(path)
          end  
          merge_tiles(r,fac.resources[path])
        end
        #}}}
      end
      private :merge_tiles

      def initialize(riddl)
        @fac = Riddl::File::Description::Resource.new("/")

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
            des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
            desres = des.find("des:resource").first
            if apply_to.empty?
              til.add_description(des,desres,"/",index,lname,block)
            else
              apply_to.each do |at|
                til.add_description(des,desres,at.to_s,index,lname,block)
              end
            end
          end
          til.compose!
        end

        ### merge tiles into a facade
        @tiles.each do |til|
          merge_tiles(til.resource)
        end
        #}}}
      end
    end
  end
end
