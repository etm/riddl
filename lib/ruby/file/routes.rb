module Riddl
  class File
    class Routing
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
            p e.dump
          end unless remove.nil?
          Message.virtual(temp,@name + "_" + suffix)
        end
        private :modify_base
        attr_reader :hash, :message, :name
        #}}}
      end

      class RouteItem
        def initialize(layer,item)
          @layer = layer
          @item = item
        end
        attr_reader :layer, :item
      end

      class Route
        #{{
        def initialize(items)
          @route = []
          @layer = 0
          items.each do |i|
            @route << RouteItem.new layer, i
          end
          @layer += 1
        end
        def initialize_copy(from)
          @rtype = from.rtype
          @route = from.route.dup
        end
        attr_accessor :route, :rtype
        #}}}
      end

      class Routes
        def initialize
          @routes = []
        end
        def add(a)
          @routes << Route.new(a)
          @routes.last
        end
      end  

      def initialize(riddl)
        #{{
        ### Forward
        @routes = Routes.new
        riddl.find("/dec:declaration/dec:interface").each do |ifa|
          layers = ifa.find("des:description|dec:filter/des:description")
          layers.first.find("des:resource/des:*[@in and @out and not(@in='*')]").each do |m|
            ri = Message.new(layers[0],m.attributes['in'])
            ro = Message.new(layers[0],m.attributes['out'])
            r = @routes.add [ri,ro]
            traverse m, ro, 
            
            unroll [ri,ro] + get_path(m.name.name,ro,layers,1), Route.new(m.name.name)
          end
          layers[0].find("des:resource/des:*[@pass and not(@pass='*')]").each do |m|
            rp = Message.new(layers[0],m.attributes['pass'])
            unroll [rp] + get_path(m.name.name,rp,layers,1), Route.new(m.name.name)
          end
          layers[0].find("des:resource/des:*[@in and @out and @in='*']").each do |m|
            ro = Message.new(layers[0],m.attributes['out'])
            unroll [Star.new,ro] + get_path(m.name.name,ro,layers,1), Route.new(m.name.name)
          end
          layers[0].find("des:resource/des:*[@add or @remove]").each do |m|
            ar = Modify.new(layers[0],m.attributes['add'],m.attributes['remove'])
            unroll [Star.new] + get_path(m.name.name,ar,layers,1), Route.new(m.name.name)
          end
          layers[0].find("des:resource/des:*[@pass and @pass='*']").each do |m|
            rs = Star.new
            unroll [Star.new] + get_path(m.name.name,rs,layers,1), Route.new(m.name.name)
          end
        end
      end

      def description
        #{{{
        doc = XML::Smart.string("<description datatypeLibrary=\"http://www.w3.org/2001/XMLSchema-datatypes\" xmlns=\"http://riddl.org/ns/description/1.0\" xmlns:xi=\"http://www.w3.org/2001/XInclude\"><resource/></description>")
        res = doc.root.children[0]
        @routes.each do |r|
          fmess = r.route.first
          lmess = r.route.last
          res.add_before(fmess.message.root).attributes['name'] = fmess.name unless fmess.class == Star
          res.add_before(lmess.message.root).attributes['name'] = lmess.name
          res.add(r.rtype, :in=>fmess.name, :out=>lmess.name)
        end
        doc
        #}}}
      end

      def unroll(tree,route,add=true)
        #{{{
        @routes << route if add
        first = true
        before_branch = nil
        tree.each do |e|
          if e.class == Array
            if first
              unroll(e,route,false)
              first = false
            else
              unroll(e,before_branch.dup,true)
            end
          else
            route.route << e
            before_branch = route.dup
          end
        end
        #}}}
      end

      def get_path(rtype,mess,layers,layer)
        #{{{
        lay = layers[layer]

        if mess.class == Message
          lay.find("des:resource/des:#{rtype}[@in and @out and not(@in='*')]").each do |m|
            cmp = Message.new(lay,m.attributes['in'])
            if cmp.hash == mess.hash
              rm = Message.new(lay,m.attributes['out'])
              if layers.length > layer+1
                return path_unroll(rm, get_path(rtype,rm,layers,layer+1))
              else
                return [rm]
              end
            end
          end

          lay.find("des:resource/des:#{rtype}[@pass and not(@pass='*')]").each do |m|
            cmp = Message.new(lay,m.attributes['pass'])
            if rm.hash == mess.hash
              if layers.length > layer+1
                return path_unroll(cmp, get_path(rtype,cmp,layers,layer+1))
              else
                return [rm]
              end
            end
          end

          lay.find("des:resource/des:*[@in and @out and @in='*']").each do |m|
            out = Message.new(lay,m.attributes['out'])
            if layers.length > layer+1
              return path_unroll(mess, get_path(rtype,out,layers,layer+1))
            else
              return [out]
            end
          end

          lay.find("des:resource/des:*[@add or @remove]").each do |m|
            ar = mess.modify(Modify.new(lay,m.attributes['add'],m.attributes['remove']))
            if layers.length > layer+1
              return path_unroll(ar, get_path(rtype,ar,layers,layer+1))
            else
              return [ar]
            end
          end
        end

        if mess.class == Modify || mess.class == Star
          matchmess = @routes.map do |r|
            r.rtype == rtype ? r.route[layer] : nil
          end.compact
          mapping = {}
          availmess = lay.find("des:resource/des:#{rtype}").map do |m|
            if !m.attributes['in'].nil? && m.attributes['in'] != "*"
              mm = Message.new(lay,m.attributes['in'])
              mapping[mm] = Message.new(lay,m.attributes['out'])
              mm
            elsif !m.attributes['pass'].nil? && m.attributes['pass'] != "*"
              pp = Message.new(lay,m.attributes['pass'])
              mapping[pp] = pp
              pp
            else
              mapping['*'] = Star
              Star
            end
          end.compact
          mdiff = availmess - matchmess
          return path_unroll(mdiff, mdiff.map{|m| get_path(rtype,mapping[m],layers,layer+1)})
        end

        []
        #}}}
      end

      def path_unroll(parent,sub)
        #{{{
        if parent.class == Array
          parent.each_with_index.map do |e,i|
            [e] + sub[i]
          end
        else
          [parent] + sub
        end
        #}}}
      end

      attr_reader :routes
      private :get_path, :path_unroll, :unroll
    end
  end  
end
