require File.expand_path(File.dirname(__FILE__) + '/description/resource')
require File.expand_path(File.dirname(__FILE__) + '/description/request')
require File.expand_path(File.dirname(__FILE__) + '/description/message_and_transformation')

module Riddl
  class Wrapper
    class Description
      def visualize(res=@resource,what='')
        #{{{
        what += res.path
        puts what
        res.requests.each do |k,v|
          puts "  #{k.upcase}:"
          v.each_with_index do |l,i|
            l.each do |r|
              puts "    #{r.class.name.gsub(/[^\:]+::/,'')}: #{r.visualize}"
            end
          end
        end
        res.resources.each do |key,r|
          visualize(r,what + (what == '/' ? ''  : '/'))
        end
        #}}}
      end

      def paths(res=@resource,what='')
        #{{{
        what += what == '' ? '/' : res.path
        ret = [[what,res.recursive]]
        res.resources.each do |name,r|
          ret += paths(r,what == '/' ? what : what + '/')
        end
        ret
        #}}}
      end

      def get_resource(path)
        #{{{
        pres = @resource
        path.split('/').each do |pa|
          next if pa == ""
          if pres.resources.has_key?(pa)
            pres = pres.resources[pa]
          else
            return nil
          end
        end
        pres
        #}}}
      end  

      def add_description(des,res,desres,path=nil,rec=nil)
        #{{{
        unless path.nil?
          unless res.resources.has_key?(path)
            res.resources[path] = Riddl::Wrapper::Description::Resource.new(path,rec.nil? ? false : true)
          end
          res = res.resources[path]
        end
        res.add_requests(des,desres,0,nil)
        desres.find("des:resource").each do |desres|
          cpath = desres.attributes['relative'] || "{}"
          rec = desres.attributes['recursive']
          add_description(des,res,desres,cpath,rec)
        end
        nil
        #}}}
      end
      private :add_description

      def initialize(riddl)
        #{{{
        @resource = Riddl::Wrapper::Description::Resource.new("/")
        des = riddl.root
        desres = des.find("des:resource").first
        add_description(des,@resource,desres)
        #}}}
      end
    end

  end
end
