require ::File.dirname(__FILE__) + '/description'

module Riddl
  class File
    class Declaration

      class Facade
        #{{{
        def initialize
          @resource = Riddl::File::Description::Resource.new("/")
        end

        def add(path)
          if path.nil? || path == '/'
            @resource
          else
            @resource.add(path)
          end
        end

        def generate_description
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
          if mode == :composition
            res.composition.each do |k,v|
              puts "  #{k.upcase}:"
              v.each do |r|
                puts "      #{r.class.name.gsub(/[^\:]+::/,'')}: #{r.visualize}"
              end
            end
          end
          res.resources.each do |key,r|
            visualize(mode,r,what + (what == '/' ? ''  : '/'))
          end
        end

        def compose(res)
          res.compose!
          res.resources.each do |key,r|
            self.compose!(r)
          end
        end
        private :compose
        #}}}
      end

      def description
        @fac.generate_description
      end

      def visualize_tree_and_layers
        @fac.visualize :layers
      end

      def visualize_tree_and_composition
        @fac.visualize :composition
      end

      def initialize(riddl)
        #{{{
        @fac = Facade.new
        ### Forward
        riddl.find("/dec:declaration/dec:facade/dec:tile").each do |tile|
          res = @fac.add(tile.attributes['path'] || '/')
          res.clean! # for overlapping tiles, each tile gets an empty path
          tile.find("dec:layer").each_with_index do |layer,index|
            apply_to = layer.find("dec:apply-to")
            lname = layer.attributes['name']
            des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
            desres = des.find("des:resource").first
            if apply_to.empty?
              res.add(des,desres,"/",index)
            else
              apply_to.each do |at|
                res.add(des,desres,at.to_s,index)
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
