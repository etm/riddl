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

      def add_description(des,res,desres,path=nil,rel="/")
        #{{{
        unless path.nil?
          unless res.resources.has_key?(path)
            res.resources[path] = Riddl::Wrapper::Description::Resource.new(path)
          end
          res = res.resources[path]
        end
        res.add_requests(des,desres,0,nil)
        desres.find("des:resource").each do |desres|
          cpath = desres.attributes['relative'] || "{}"
          add_description(des,res,desres,cpath,(rel+"/"+cpath).gsub(/\/+/,'/'))
        end
        nil
        #}}}
      end
      private :add_description

      def initialize(riddl)
        @resource = Riddl::Wrapper::Description::Resource.new("/")
        des = riddl.root
        desres = des.find("des:resource").first
        add_description(des,@resource,desres)
      end
    end

  end
end
