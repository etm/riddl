require ::File.dirname(__FILE__) + '/description'
require ::File.dirname(__FILE__) + '/../error'

module Riddl
  class File
    class Declaration

      class Facade
        #{{{
        def initialize
          @resource = Riddl::File::Description::Resource.new("/")
        end

        def generate_description_xml
          @resource.to_xml
        end
        
        def to_xml
          #{{{
          result = ""
          messages = {}
          names = []
          messages_result = ""
          to_xml_priv(result,messages,0)
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

        def to_xml_priv(result,messages,level)
          #{{{
          s = "  " * (level + 1)
          t = "  " * (level + 2)
          result << s + "<resource#{@path != '/' && @path != '' ? " relative=\"#{@path}\"" : ''}>\n"
          @composition.each do |k,v|
            v.each do |m|
              m = m.result
              if %w{get post put delete}.include?(k)
                result << t + "<#{k} "
              else
                result << t + "<request method=\"#.upcase{k}\" "
              end  
              case m
                when RequestInOut
                  result << "in=\"#{m.in.name}\""
                  messages[m.in.hash] = m.in
                  unless m.out.nil?
                    result << " out=\"#{m.out.name}\""
                    messages[m.out.hash] = m.out
                  end  
                when RequestStarOut  
                  result << "in=\"*\""
                  unless m.out.nil?
                    result << " out=\"#{m.out.name}\""
                    messages[m.out.hash] = m.out
                  end  
                when RequestPass
                  result << "pass=\"#{m.pass.name}\""
                  messages[m.pass.hash] = m.pass
                when RequestTransformation
                  result << "transformation=\"#{m.trans.name}\""
                  messages[m.trans.hash] = m.trans
              end  
              result << "/>\n"
            end  
          end
          @resources.each do |k,v|
            v.to_xml_priv(result,messages,level+1)
          end
          ""
          result << s + "</resource>\n"
          #}}}
        end

        attr_reader :resource
        #}}}
      end

      class Tile
        #{{
        def initialize
          #{{{
          @resource = Riddl::File::Description::Resource.new("/")
          @base_path = @resource
          #}}}
        end
        
        def visualize(mode,res=@resource,what='')
          #{{{
          what += res.path
          puts what
          if mode == :layers
            res.requests.each do |k,v|
              puts "  #{k.upcase}:"
              v.each_with_index do |l,i|
                puts "    Layer #{i}:"
                l.each do |r|
                  puts "      #{r.class.name.gsub(/[^\:]+::/,'')}: #{r.visualize}"
                end
              end
            end
          end
          if mode == :facade
            res.composition.each do |k,v|
              puts "  #{k.upcase}:"
              v.each do |r|
                puts "    #{r.result.class.name.gsub(/[^\:]+::/,'')}: #{r.result.visualize}"
                r.route.each do |ritem|
                  puts "      #{ritem.class.name.gsub(/[^\:]+::/,'')}: #{ritem.visualize}"
                end unless r.route.nil?
              end
            end
          end
          res.resources.each do |key,r|
            visualize(mode,r,what + (what == '/' ? ''  : '/'))
          end
          #}}}
        end

        def add_description(des,desres,path,index,block,res=@base_path,rel="/")
          #{{
          res = add_path(path,res)
          res.add_requests(des,desres,index)
          block.each do |bl|
            bpath = bl.to_s.gsub(/\/+/,'/').gsub(/\/$/,'')
            bpath = (bpath == "" ? "/" : bpath)
            if rel == bpath
              res.remove_requests(des,bl.attributes)
            end  
          end  
          res.compose!
          desres.find("des:resource").each do |desres|
            cpath = desres.attributes['relative'] || "{}"
            add_description(des,desres,cpath,index,block,res,(rel+"/"+cpath).gsub(/\/+/,'/'))
          end
          nil
          #}}}
        end

        def add_path(path,res)
          #{{{
          pres = res
          path.split('/').each do |p|
            next if p == ""
            unless pres.resources.has_key?(p)
              pres.resources[p] = Riddl::File::Description::Resource.new(p)
            end
            pres = pres.resources[p]
          end
          pres
          #}}}
        end
        private :add_path

        def base_path(path)
          #{{{
          if path.nil? || path == '/'
            @base_path
          else
            @base_path = add_path(path,@base_path)
          end
          #}}}
        end

        attr_reader :resource
        #}}}
      end

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
              til.add_description(des,desres,"/",index,block)
            else
              apply_to.each do |at|
                til.add_description(des,desres,at.to_s,index,block)
              end
            end
          end
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
