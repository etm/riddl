gem 'ruby-xml-smart', '>= 0.1.14'
require 'xml/smart'

module Riddl
  class File < XML::Smart
    #{{{
    def self::open(name)
      doc = superclass::open(name)
      doc.xinclude!
      doc.namespaces = {
        'dec' => "http://riddl.org/ns/declaration/1.0",
        'des' => "http://riddl.org/ns/description/1.0"
      }
      (class << doc; self; end).class_eval do
        def validate!
          return self.validate_against(XML::Smart.open("#{::File.dirname(__FILE__)}/../../ns/description-1_0.rng")) if @description
          return self.validate_against(XML::Smart.open("#{::File.dirname(__FILE__)}/../../ns/declaration-1_0.rng")) if @declaration
          nil
        end

        def __riddl_init
          qname = self.root.name
          @description = qname.namespace == "http://riddl.org/ns/description/1.0" && qname.name ==  "description"
          @declaration = qname.namespace == "http://riddl.org/ns/declaration/1.0" && qname.name ==  "declaration"
        end

        def declaration?
          @declaration
        end
        def description?
          @description
        end

        def valid_resources?
          @description ? check_rec_resources(self.find("/des:description/des:resource")) : []
        end

        def check_rec_resources(res,path='')
          messages = []
          res.each do |res|
            path = if path == ''
              '/'
            else
              res.attributes['relative'].nil? ? path + '{}/' : path + res.attributes['relative'] + '/'
            end
            %w{post get put delete}.each do |mt|
              ifield = {}; pfield = {}
              ofield = []; afield = []; rfield = []
              cfield = 0
              res.find("des:#{mt}").each do |e|
                a = e.attributes
                if !a['in'].nil? && a['in'] != '*'
                  ifield[a['in']] ||= 0
                  ifield[a['in']] += 1
                end
                if !a['pass'].nil? && a['pass'] != '*'
                  pfield[a['pass']] ||= 0
                  pfield[a['pass']] += 1
                end
                ofield << a['out'] unless a['out'].nil?
                afield << a['add'] unless a['add'].nil?
                rfield << a['remove'] unless a['remove'].nil?
                cfield += 1 if !a['remove'].nil? || !a['add'].nil? || a['in'] == '*' || a['pass'] == '*'
              end
              what = "#{path.gsub(/(.)\/$/,'\1')} -> #{mt}"
              messages += check_multi_fields(ifield,what,"in")
              messages += check_multi_fields(pfield,what,"pass")
              messages += check_fields(ofield,what,"out")
              messages += check_fields(afield,what,"add")
              messages += check_fields(rfield,what,"remove")
              puts "#{what}: more than one catchall (*) operation is not allowed." if cfield > 1
            end
            messages += check_rec_resources(res.find("des:resource"),path)
          end
          messages
        end

        def check_fields(field, what, name)
          messages = []
          field.compact.each do |k|
            if self.find("/des:description/des:message[@name='#{k}']").empty?
              messages << "#{what}: #{name} message '#{k}' not found."
            end unless k == '*'
          end
          messages
        end

        def check_multi_fields(field, what, name)
          messages = []
          field.each do |k,v|
            if self.find("/des:description/des:message[@name='#{k}']").empty?
              messages << "#{what}: #{name} message '#{k}' not found."
            end unless k == '*'
            if v > 1
              messages << "#{what}: #{name} message '#{k}' is allowed to occur only once."
            end
          end
          messages
        end

      end
      doc.__riddl_init
      doc
    end
    #}}}
  end

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
        @add = XML::Smart::string(layer.find("des:message[@name='#{add}']").first.dump)
        @add.find("/message/@name").delete_all!
        @hash += @add.to_s.hash
      end
      unless remove.nil?
        @remove = XML::Smart::string(layer.find("des:message[@name='#{remove}']").first.dump)
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
      @message = XML::Smart::string(layer.find("des:message[@name='#{name}']").first.dump)
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
      ar.class == Riddl::Modify ? modify_base(ar.add,ar.remove,"f") : nil
    end
    def modify_back(ar)
      ar.class == Riddl::Modify ? modify_base(ar.remove,ar.add,"b") : nil
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
      Riddl::Message.virtual(temp,@name + "_" + suffix)
    end
    private :modify_base
    attr_reader :hash, :message, :name
    #}}}
  end

  class Route
    #{{{
    def initialize(rtype)
      @rtype = rtype
      @route = []
    end
    def initialize_copy(from)
      @rtype = from.rtype
      @route = from.route.dup
    end
    attr_accessor :route, :rtype
    #}}}
  end

  class Routes
    def initialize(riddl)
      #{{{
      ### Forward
      @routes = []
      riddl.find("/dec:declaration/dec:interface").each do |ifa|
        layers = ifa.find("des:description|dec:filter/des:description").to_a
        layers[0].find("des:resource/des:*[@in and @out and not(@in='*')]").each do |m|
          ri = Riddl::Message.new(layers[0],m.attributes['in'])
          ro = Riddl::Message.new(layers[0],m.attributes['out'])
          unroll [ri,ro] + get_path(m.name.name,ro,layers,1), Riddl::Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@pass and not(@pass='*')]").each do |m|
          rp = Riddl::Message.new(layers[0],m.attributes['pass'])
          unroll [rp,rp] + get_path(m.name.name,rp,layers,1), Riddl::Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@in and @out and @in='*']").each do |m|
          ro = Riddl::Message.new(layers[0],m.attributes['out'])
          unroll [Riddl::Star.new,ro] + get_path(m.name.name,ro,layers,1), Riddl::Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@add or @remove]").each do |m|
          ar = Riddl::Modify.new(layers[0],m.attributes['add'],m.attributes['remove'])
          unroll [ar] + get_path(m.name.name,ar,layers,1), Riddl::Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@pass and @pass='*']").each do |m|
          rs = Riddl::Star.new
          unroll [rs] + get_path(m.name.name,rs,layers,1), Riddl::Route.new(m.name.name)
        end
      end
      ### Backward
      @routes.each do |r|
        last = nil
        (r.route.length-1).downto(0) do |i|
          m = r.route[i]
          unless last.nil?
            if last.class == Riddl::Message && m.class == Riddl::Star && i > 0 # except leading star
              r.route[i] = last
            elsif last.class == Riddl::Message && m.class == Riddl::Modify
              r.route[i] = last.modify_back(m)
            end
          end
          last = r.route[i]
        end
      end
      #}}}
    end

    def description
      #{{{
      doc = XML::Smart.string("<description datatypeLibrary=\"http://www.w3.org/2001/XMLSchema-datatypes\" xmlns=\"http://riddl.org/ns/description/1.0\" xmlns:xi=\"http://www.w3.org/2001/XInclude\"><resource/></description>")
      res = doc.root.children[0]
      @routes.each do |r|
        fmess = r.route.first
        lmess = r.route.last
        res.add_before(fmess.message.root).attributes['name'] = fmess.name unless fmess.class == Riddl::Star
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

      if mess.class == Riddl::Message
        lay.find("des:resource/des:#{rtype}[@in and @out and not(@in='*')]").each do |m|
          cmp = Riddl::Message.new(lay,m.attributes['in'])
          if cmp.hash == mess.hash
            rm = Riddl::Message.new(lay,m.attributes['out'])
            if layers.length > layer+1
              return path_unroll(rm, get_path(rtype,rm,layers,layer+1))
            else
              return [rm]
            end
          end
        end

        lay.find("des:resource/des:#{rtype}[@pass and not(@pass='*')]").each do |m|
          cmp = Riddl::Message.new(lay,m.attributes['pass'])
          if rm.hash == mess.hash
            if layers.length > layer+1
              return path_unroll(cmp, get_path(rtype,cmp,layers,layer+1))
            else
              return [rm]
            end
          end
        end

        lay.find("des:resource/des:*[@in and @out and @in='*']").each do |m|
          out = Riddl::Message.new(lay,m.attributes['out'])
          if layers.length > layer+1
            return path_unroll(mess, get_path(rtype,out,layers,layer+1))
          else
            return [out]
          end
        end

        lay.find("des:resource/des:*[@add or @remove]").each do |m|
          ar = mess.modify(Riddl::Modify.new(lay,m.attributes['add'],m.attributes['remove']))
          if layers.length > layer+1
            return path_unroll(ar, get_path(rtype,ar,layers,layer+1))
          else
            return [ar]
          end
        end
      end

      if mess.class == Riddl::Modify || mess.class == Riddl::Star
        matchmess = @routes.map do |r|
          r.rtype == rtype ? r.route[layer] : nil
        end.compact
        mapping = {}
        availmess = lay.find("des:resource/des:#{rtype}").map do |m|
          if !m.attributes['in'].nil? && m.attributes['in'] != "*"
            mm = Riddl::Message.new(lay,m.attributes['in'])
            mapping[mm] = Riddl::Message.new(lay,m.attributes['out'])
            mm
          elsif !m.attributes['pass'].nil? && m.attributes['pass'] != "*"
            pp = Riddl::Message.new(lay,m.attributes['pass'])
            mapping[pp] = pp
            pp
          else
            mapping['*'] = Riddl::Star
            Riddl::Star
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
