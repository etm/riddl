module Riddl
  class Wrapper
    class Declaration < WrapperUtils

      class Tile
        #{{
        def initialize
          #{{{
          @resource = Riddl::Wrapper::Description::Resource.new("/")
          @base_path = @resource
          #}}}
        end
        
        def visualize(mode,res=@resource,what='')
          #{{{
          what += res.path
          puts what
          if mode == :layers
            res.access_methods.each do |k,v|
              puts "  #{k.upcase}:"
              v.each_with_index do |l,i|
                puts "    Layer #{i}:"
                l.each do |r|
                  puts "      #{r.class.name.gsub(/[^\:]+::/,'')}: #{r.visualize}"
                end unless l.nil?
              end
            end
          end
          if mode == :composition
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

        def add_description(des,desres,path,index,interface,block,rec=nil,res=@base_path)
          #{{{
          res = add_path(path,res,rec)
          res.add_access_methods(des,desres,index,interface)
          block.each do |bl|
            bpath = bl.to_s.gsub(/\/+/,'/').gsub(/\/$/,'')
            bpath = (bpath == "" ? "/" : bpath)
            if interface.sub == bpath
              res.remove_access_methods(des,bl.attributes)
            end  
          end
          desres.find("des:resource").each do |desres|
            cpath = desres.attributes['relative'] || "{}"
            rec = desres.attributes['recursive']
            int = Interface.new_from_interface(interface,(interface.sub+"/"+cpath).gsub(/\/+/,'/'))
            add_description(des,desres,cpath,index,int,block,rec,res)
          end
          nil
          #}}}
        end
          
        def compose!(res=@base_path)
          #{{{
          res.compose!
          res.resources.each do |k,r|
            compose!(r)
          end
          #}}}
        end

        def add_path(path,res,rec=nil)
          #{{{
          pres = res
          path.split('/').each do |pa|
            next if pa == ""
            unless pres.resources.has_key?(pa)
              pres.resources[pa] = Riddl::Wrapper::Description::Resource.new(pa,rec.nil? ? false : true)
            end
            pres = pres.resources[pa]
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

    end
  end
end
