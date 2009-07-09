module Riddl
  class File
    class Declaration
      class Star
        #{{{
        def name
          "*"
        end
        def eql?(other)
          other.class == self.class
        end
        #}}}
      end

      class Modify
        #{{{
        def initialize(layer,add,remove)
          @add = @remove = nil
          @add_name = add
          @remove_name = remove
          @hash = 0
          unless add.nil?
            @add = layer.find("des:add[@name='#{add}']").first.to_doc
            @add.find("/message/@name").delete_all!
            @hash += @add.to_s.hash
          end
          unless remove.nil?
            @remove = layer.find("des:remove[@name='#{remove}']").first.to_doc
            @remove.find("/message/@name").delete_all!
            @hash += @remove.to_s.hash
          end
        end
        def eql?(other)
          other.class == self.class && (self === other || self.hash == other.hash)
        end
        attr_reader :add, :remove, :hash
        #}}}
      end

      class Message
        #{{{
        def initialize(layer,name)
          @message = layer.find("des:message[@name='#{name}']").first.to_doc
          @message.find("/message/@name").delete_all!
          @hash = @message.to_s.hash
          @name = name
        end
        def self::virtual(message,name)
          o = allocate
          o.instance_variable_set(:@message,message)
          o.instance_variable_set(:@hash,message.to_s.hash)
          o.instance_variable_set(:@name,name)
          o
        end
        def eql?(other)
          other.class == self.class && (self === other || self.hash == other.hash)
        end
        def modify(ar)
          ar.class == Modify ? modify_base(ar.add,ar.remove,"f") : nil
        end
        def modify_back(ar)
          ar.class == Modify ? modify_base(ar.remove,ar.add,"b") : nil
        end
        def modify_base(add,remove,suffix)
          temp = @message.dup
          add.root.children.each do |e|
            if e.name.name == "parameter"
              pos = temp.find("/message/part[0]")
              pos.empty? ? temp.root.add(e) : pos.first.add_before(e)
            else
              temp.root.add(e)
            end
          end unless add.nil?
          remove.root.children.each do |e|
            # TODO
          end unless remove.nil?
          Message.virtual(temp,@name + "_" + suffix)
        end
        private :modify_base
        attr_reader :hash, :message, :name
        #}}}
      end

      class Resource
        #{{
        def initialize(path=nil)
          @path = path
          @resources = {}
          @requests = {}
          @composition = {}
        end
        def compose!
          
        end
        def add(path)
          pres = self
          path.split('/').each do |p|
            next if p == ""
            unless pres.resources.has_key?(p) 
              pres.resources[p] = Resource.new(p)
            end
            pres = pres.resources[p]
          end
          pres
        end
        def clean!
          @resouces = {}
        end
        def add_request_in_out(index,method,min,mout)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestInOut.new(min,mout)
        end
        def add_request_transform(index,method,madd,mremove)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestTransform.new(madd,mremove)
        end
        def add_request_star_out(index,method,mout)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestStarOut.new(mout)
        end
        def add_request_pass(index,method)
          @requests[method] ||= []
          @requests[method][index] ||= []
          @requests[method][index] << RequestPass.new
        end
        attr_reader :resources,:path,:requests
        #}}}
      end  
          
      class Facade
        #{{{
        def initialize
          @resource = Resource.new("/")
        end
        def add(path)
          if path.nil? || path == '/'
            @resource
          else
            @resource.add(path)
          end
        end
        def visualize(res=@resource,what='')
          what += res.path
          puts what
          res.requests.each do |k,v|
            puts "  #{k.upcase}:"
            v.each_with_index do |l,i|
              puts "    Layer #{i}:"
              l.each do |r|
                 puts "      #{r.class.name}"
              end
            end
          end
          res.resources.each do |key,r|
            visualize(r,what + (what == '/' ? ''  : '/'))
          end
        end
        def compose!(res=@resource)
          res.compose!
          res.resources.each do |key,r|
            self.compose!(r)
          end
        end
        #}}}
      end  

      # Request* helper classes
      #{{{
      class RequestInOut
        def initialize(min,mout)
          @in = min
          @out = mout
        end
      end  
      class RequestTransform
        def initialize(madd,mremove)
          @add = madd
          @remove = mremove
        end
      end  
      class RequestStarOut
        def initialize(mout)
          @out = mout
        end
      end  
      class RequestPass; end
      #}}}

      def apply_to(res,des,desres,path,index)
        #{{{
        res = res.add(path)
        add_requests(res,desres,index)
        desres.find("des:resource").each do |desres|
          apply_to(res,des,desres,desres.attributes['relative'] || "{}",index)
        end
        #}}}
      end
      private :apply_to

      def add_requests(res,desres,index)
        #{{{
        desres.find("des:*[@in and not(@in='*')]").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_in_out(index,method,m.attributes['in'],m.attributes['out'])
        end
        desres.find("des:*[@pass and not(@pass='*')]").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_in_out(index,method,m.attributes['pass'],m.attributes['pass'])
        end
        desres.find("des:*[@add or @remove]").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_transform(index,method,m.attributes['add'],m.attributes['remove'])
        end
        desres.find("des:*[@in and @in='*']").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_star_out(index,method,m.attributes['out'])
        end
        desres.find("des:*[@pass and @pass='*']").each do |m|
          method = m.attributes['method'] || m.name.name
          res.add_request_pass(index,method)
        end
        #}}}
      end
      private :add_requests

      def description
      end

      def initialize(riddl)
        #{{{
        fac = Facade.new
        ### Forward
        riddl.find("/dec:declaration/dec:facade/dec:tile").each do |tile|
          res = fac.add(tile.attributes['path'] || '/')
          res.clean! # for overlapping tiles, each tile gets an empty path
          tile.find("dec:layer").each_with_index do |layer,index|
            apply_to = layer.find("dec:apply-to")
            lname = layer.attributes['name']
            des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
            desres = des.find("des:resource").first
            if apply_to.empty?
              apply_to(res,des,desres,"/",index)
            else  
              apply_to.each do |at|
                apply_to(res,des,desres,at.to_s,index)
              end
            end
          end
        end
        fac.visualize
        fac.compose!
        #}}}
      end
    end
  end  
end
