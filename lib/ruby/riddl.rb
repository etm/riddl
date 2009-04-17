gem 'ruby-xml-smart', '>= 0.1.14'
require 'xml/smart'

module Riddl
  class File < XML::Smart
    def self::open(name)
      doc = superclass::open(name)
      doc.xinclude!
      doc.namespaces = {
        'dec' => "http://riddl.org/ns/declaration/1.0",
        'des' => "http://riddl.org/ns/description/1.0"
      }
      (class << doc; self; end).class_eval do
        def get_message(path,operation,params)
          #{{{
          if description?
            tpath = path == "/" ? "/des:resource/" : path.gsub(/\/([^{}\/]+)/,"/des:resource[@relative=\"\\1\"]").gsub(/\/\{\}/,"des:resource[not(@relative)]")
            tpath = "/des:description" + tpath + "des:" + operation
            self.find(tpath + "[@in and not(@in='*')]").each do |o|
              return o.attributes['in'] if check_message(o.attributes['in'],params)
            end
            self.find(tpath + "[@pass and not(@pass='*')]").each do |o|
              return o.attributes['pass'] if check_message(o.attributes['pass'],params)
            end
            self.find(tpath + "[@in and @in='*']").each do
              return "*"
            end
            self.find(tpath + "[@add or @remove]").each do
              return "*"
            end
            self.find(tpath + "[@pass and @pass='*']").each do
              return "*"
            end
          end
          nil
          #}}}
        end

        def check_message(name,mparas)
          #self.find("/des:description/des:message[@name='#{name}']").each do |m|
          #  mparts = m.children
          #  cparts = 0
          #  cparas = 0
          #  loop do
          #    part = mparts[cparts]
          #    para = mparas[cparas]

          #    #case mparts.attributes['occurs']
          #    #  when '+'
          #    #    if 
          #    #  when '*'
          #    #  when '?'
          #    #end  

          #  params.each do |param|
          #    if param.name == mparts[0].attributes['name']
          #    pp p.attributes['name']
          #    pp params[i]
          #    p "-------"
          #  end
          #  end
          #end
        end

        def validate!
          #{{{
          return self.validate_against(XML::Smart.open("#{::File.dirname(__FILE__)}/../../ns/description-1_0.rng")) if @description
          return self.validate_against(XML::Smart.open("#{::File.dirname(__FILE__)}/../../ns/declaration-1_0.rng")) if @declaration
          nil
          #}}}
        end

        def __riddl_init
          #{{{
          qname = self.root.name
          @description = qname.namespace == "http://riddl.org/ns/description/1.0" && qname.name ==  "description"
          @declaration = qname.namespace == "http://riddl.org/ns/declaration/1.0" && qname.name ==  "declaration"
          #}}}
        end

        def paths
          #{{{
          (@description ? get_paths(self.find("/des:description/des:resource")) : []).map do |p|
            [p,Regexp.new("^" + p.gsub(/\{\}/,"[^/]+") + "$")]
          end
          #}}}
        end

        def get_paths(res,path='')
          #{{{
          tpath = []
          res.each do |res|
            tpath << xpath = if path == ''
              '/'
            else
              res.attributes['relative'].nil? ? path.dup << '{}/' : path.dup << res.attributes['relative'] + '/'
            end
            tpath += get_paths(res.find("des:resource[@relative]"),xpath) 
            tpath += get_paths(res.find("des:resource[not(@relative)]"),xpath) 
          end  
          tpath
          #}}}
        end
        private :get_paths

        def declaration?
          #{{{
          @declaration
          #}}}
        end
        def description?
          #{{{
          @description
          #}}}
        end

        def valid_resources?
          #{{{
          @description ? check_rec_resources(self.find("/des:description/des:resource")) : []
          #}}}
        end

        def check_rec_resources(res,path='')
          #{{{
          messages = []
          res.each do |res|
            tpath = if path == ''
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
              what = "#{tpath} -> #{mt}"
              messages += check_multi_fields(ifield,what,"in")
              messages += check_multi_fields(pfield,what,"pass")
              messages += check_fields(ofield,what,"out")
              messages += check_fields(afield,what,"add")
              messages += check_fields(rfield,what,"remove")
              puts "#{what}: more than one catchall (*) operation is not allowed." if cfield > 1
            end
            messages += check_rec_resources(res.find("des:resource"),tpath)
          end
          messages
          #}}}
        end
        private :check_rec_resources

        def check_fields(field, what, name)
          #{{{
          messages = []
          field.compact.each do |k|
            if self.find("/des:description/des:message[@name='#{k}']").empty?
              messages << "#{what}: #{name} message '#{k}' not found."
            end unless k == '*'
          end
          messages
          #}}}
        end
        private :check_fields

        def check_multi_fields(field, what, name)
          #{{{
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
          #}}}
        end
        private :check_multi_fields
      end
      doc.__riddl_init
      doc
    end
    #}}}
  end

  class Routes
    #{{{
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

    def initialize(riddl)
      #{{{
      ### Forward
      @routes = []
      riddl.find("/dec:declaration/dec:interface").each do |ifa|
        layers = ifa.find("des:description|dec:filter/des:description").to_a
        layers[0].find("des:resource/des:*[@in and @out and not(@in='*')]").each do |m|
          ri = Message.new(layers[0],m.attributes['in'])
          ro = Message.new(layers[0],m.attributes['out'])
          unroll [ri,ro] + get_path(m.name.name,ro,layers,1), Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@pass and not(@pass='*')]").each do |m|
          rp = Message.new(layers[0],m.attributes['pass'])
          unroll [rp,rp] + get_path(m.name.name,rp,layers,1), Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@in and @out and @in='*']").each do |m|
          ro = Message.new(layers[0],m.attributes['out'])
          unroll [Star.new,ro] + get_path(m.name.name,ro,layers,1), Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@add or @remove]").each do |m|
          ar = Modify.new(layers[0],m.attributes['add'],m.attributes['remove'])
          unroll [ar] + get_path(m.name.name,ar,layers,1), Route.new(m.name.name)
        end
        layers[0].find("des:resource/des:*[@pass and @pass='*']").each do |m|
          rs = Star.new
          unroll [rs] + get_path(m.name.name,rs,layers,1), Route.new(m.name.name)
        end
      end
      ### Backward
      @routes.each do |r|
        last = nil
        (r.route.length-1).downto(0) do |i|
          m = r.route[i]
          unless last.nil?
            if last.class == Message && m.class == Star && i > 0 # except leading star
              r.route[i] = last
            elsif last.class == Message && m.class == Modify
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
    #}}}
  end
  
  class HttpParser
    #{{{
    class Param
      #{{{
      def initialize(type,name,data)
        name =~ %r([\[\]]*([^\[\]]+)\]*)
        @name = $1 || ''
        @data = data
        @type = type
      end
      attr_reader :name, :data, :type
      #}}}
    end

    MULTIPART_CONTENT_TYPES = [
      #{{{
      'multipart/form-data',
      'multipart/related',
      'multipart/mixed'
      #}}}
    ]
    FORM_CONTENT_TYPES = [
      #{{{
      nil,
      'application/x-www-form-urlencoded'
      #}}}
    ]  
    EOL = "\r\n"
    D = '&;'

    def unescape(s)
      #{{{
      s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
      #}}}
    end
    private :unescape

    def parse_content(input,ctype,content_length,content_disposition,content_id)
      #{{{
      filename = content_disposition[/ filename="?([^\";]*)"?/ni, 1]
      name = content_disposition[/ name="?([^\";]*)"?/ni, 1] || content_id

      if ctype || filename
        body = Tempfile.new("RackMultipart")
        body.binmode if body.respond_to?(:binmode)
      end
      
      bufsize = 16384
         
      until content_length <= 0
        c = input.read(bufsize < content_length ? bufsize : content_length)
        raise EOFError, "bad content body"  if c.nil? || c.empty?
        body << c
        content_length -= c.size
      end  
      
      add_to_params(name,body,filename,ctype,nil)
      #}}}
    end
    private :parse_content

    def parse_multipart(input,content_type,content_length)
      #{{{
      content_type =~ %r|\Amultipart/.*boundary=\"?([^\";,]+)\"?|n
      boundary = "--#{$1}"

      boundary_size = boundary.size + EOL.size
      content_length -= boundary_size
      status = input.read(boundary_size)
      raise EOFError, "bad content body" unless status == boundary + EOL

      rx = /(?:#{EOL})?#{Regexp.quote boundary}(#{EOL}|--)/n

      buf = ""
      bufsize = 16384
      loop do
        head = nil
        body = ''
        filename = ctype = name = nil

        until head && buf =~ rx
          if !head && i = buf.index(EOL+EOL)
            head = buf.slice!(0, i+2) # First \r\n
            buf.slice!(0, 2)          # Second \r\n

            filename = head[/Content-Disposition:.* filename="?([^\";]*)"?/ni, 1]
            ctype = head[/Content-Type: (.*)#{EOL}/ni, 1]
            name = head[/Content-Disposition:.*\s+name="?([^\";]*)"?/ni, 1] || head[/Content-ID:\s*([^#{EOL}]*)/ni, 1]

            if ctype || filename
              body = Tempfile.new("RackMultipart")
              body.binmode  if body.respond_to?(:binmode)
            end

            next
          end

          # Save the read body part.
          if head && (boundary_size+4 < buf.size)
            body << buf.slice!(0, buf.size - (boundary_size+4))
          end

          c = input.read(bufsize < content_length ? bufsize : content_length)
          raise EOFError, "bad content body"  if c.nil? || c.empty?
          buf << c
          content_length -= c.size
        end

        # Save the rest.
        if i = buf.index(rx)
          body << buf.slice!(0, i)
          buf.slice!(0, boundary_size+2)
          content_length = -1  if $1 == "--"
        end

        add_to_params(name,body,filename,ctype,head)

        break if buf.empty? || content_length == -1
      end
      #}}}
    end
    private :parse_multipart

    def add_to_params(name,body,filename,ctype,head)
      #{{{
      if filename == ""
        # filename is blank which means no file has been selected
      elsif filename && ctype
        body.rewind

        # Take the basename of the upload's original filename.
        # This handles the full Windows paths given by Internet Explorer
        # (and perhaps other broken user agents) without affecting
        # those which give the lone filename.
        filename =~ /^(?:.*[:\\\/])?(.*)/m
        filename = $1

        @params << Param.new(:part, name, :filename => filename, :type => ctype, :tempfile => body, :head => head)
      elsif !filename && ctype
        body.rewind
        
        # Generic multipart cases, not coming from a form
        @params << Param.new(:part, name, :type => ctype, :tempfile => body, :head => head)
      else
        @params << Param.new(:parameter, name, body)
      end
      #}}}
    end
    private :add_to_params

    def parse_nested_query(qs, type)
      #{{{
      (qs || '').split(/[#{D}] */n).each do |p|
        k, v = unescape(p).split('=', 2)
        @params << Param.new(type,k,v)
      end
      #}}}
    end
    private :parse_nested_query

    def initialize(query_string,input,content_type,content_length,content_disposition,content_id)
      #{{{
      media_type = content_type && content_type.split(/\s*[;,]\s*/, 2).first.downcase
      @params = []
      parse_nested_query(query_string,:query)
      if MULTIPART_CONTENT_TYPES.include?(media_type)
        parse_multipart(input,content_type,content_length.to_i)
      elsif FORM_CONTENT_TYPES.include?(media_type)
        # sub is a fix for Safari Ajax postings that always append \0
        parse_nested_query(input.sub(/\0\z/, ''),:parameter)
      else 
        parse_content(input,content_type,content_length.to_i,content_disposition||'',content_id||'')
      end

      begin
        input.rewind if input.respond_to?(:rewind)
      rescue Errno::ESPIPE
        # Handles exceptions raised by input streams that cannot be rewound
        # such as when using plain CGI under Apache
      end
      #}}}
    end

    attr_reader :params
    #}}}
  end
  
  class Implementation
    #{{{
    #}}}  
  end

  class Server
    attr_reader :env, :req, :res

    def initialize(description,&blk)
      @description = Riddl::File::open(description)
      raise 'No RIDDL description found.' unless @description.description?
      raise 'RIDDL description does not conform to specification' unless @description.validate!
      raise 'RIDDL description contains invalid resources' unless @description.valid_resources?
      @paths = @description.paths
      @blk = blk
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      @env = env
      @req = Rack::Request.new(env)
      @res = Rack::Response.new
      @riddl_path = @paths.find{ |e| e[1] =~ env["PATH_INFO"].sub(/\/*$/,'/') }
      if @riddl_path
        params = Riddl::HttpParser.new(
          @env['QUERY_STRING'],
          @env['rack.input'],
          @env['CONTENT_TYPE'],
          @env['CONTENT_LENGTH'],
          @env['HTTP_CONTENT_DISPOSITION'],
          @env['HTTP_CONTENT_ID']
        ).params
        @riddl_operation = @req.env['REQUEST_METHOD'].downcase
        @riddl_message_name = @description.get_message(@riddl_path[0],@riddl_operation,params)
        if @riddl_message_name
          @path = ''
          instance_eval(&@blk)
        else  
          @res.status = 404
        end
      else
        @res.status = 404
      end
      p "---"
      @res.finish
    end
  
    def on(resource, &block)
      @path << (@path == '' ? '/' : resource)
      yield
      @path = ::File.dirname(@path)
    end

    def run(what)
      if what.class == Class and what.superclass == Riddl::Implementation
        # w = what.new
        # check w.message
        # @res.status = w.status 
        # if w.status == 200
        #   generiere body
        # end
      end
    end

    def post(min); check(min) && @riddl_operation == 'post' end
    def get(min); check(min) && @riddl_operation == 'get' end
    def delete(min); check(min) && @riddl_operation == 'delete' end
    def put(min); check(min) && @riddl_operation == 'put' end
    def check(min)
       @path == @riddl_path[0] && min == @riddl_message_name
    end

    def resource(path=nil); path.nil? ? '{}/' : path + '/' end
  end
end
