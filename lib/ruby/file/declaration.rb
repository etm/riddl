require ::File.dirname(__FILE__) + '/description'

module Riddl
  class File
    class Declaration

      class Facade
        #{{{
        def initialize
          @resource = Riddl::File::Description::Resource.new("/")
        end

        def add_path(path)
          if path.nil? || path == '/'
            @resource
          else
            @resource.add_path(path)
          end
        end

        def generate_description_xml
          @resource.to_xml
        end
        
        def compose!
          compose(@resource)
        end

        def visualize(mode,res=@resource,what='')
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
              #v.each do |r|
              #  puts "    #{r.result.class.name.gsub(/[^\:]+::/,'')}: #{r.result.visualize}"
              #  r.route.each do |ritem|
              #    puts "      #{ritem.class.name.gsub(/[^\:]+::/,'')}: #{ritem.visualize}"
              #  end unless r.nil?
              #end
            end
          end
          res.resources.each do |key,r|
            visualize(mode,r,what + (what == '/' ? ''  : '/'))
          end
        end

        def compose(res)
          res.compose!
          res.resources.each do |key,r|
            compose(r)
          end
        end
        private :compose
        #}}}
      end

      def description_xml
        @fac.generate_description_xml
      end

      def visualize_tree_and_layers
        @fac.visualize :layers
      end

      def visualize_tree_and_facade
        @fac.visualize :facade
      end

      def initialize(riddl)
        #{{{
        @fac = Facade.new
        ### Forward
        riddl.find("/dec:declaration/dec:facade/dec:tile").each do |tile|
          res = @fac.add_path(tile.attributes['path'] || '/')
          res.clean! # for overlapping tiles, each tile gets an empty path
          tile.find("dec:layer").each_with_index do |layer,index|
            apply_to = layer.find("dec:apply-to")
            lname = layer.attributes['name']
            des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
            desres = des.find("des:resource").first
            if apply_to.empty?
              res.add_description(des,desres,"/",index)
            else
              apply_to.each do |at|
                res.add_description(des,desres,at.to_s,index)
              end
            end
          end
        end
        @fac.compose!
        #}}}
      end
    end
  end
end
