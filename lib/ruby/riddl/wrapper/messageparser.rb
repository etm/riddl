module Riddl
  class Wrapper
    class MessageParser
      def initialize(params,headers)
        #{{{
        @mist = params
        @mistp = 0
        @headp = {}
        headers.each do |k,v|
          if v.nil?
            @headp[k.name.upcase.gsub(/\-/,'_')] = k.value
          else  
            @headp[k.upcase.gsub(/\-/,'_')] = v
          end  
        end

        @numparams = 0
        #}}}
      end

      def check(what,ignore_name=false)
        #{{{
        # reset for subsequent calls
        @mistp = 0
        @numparams = 0

        # out not available
        return true if what.nil? && @mist.empty?

        # do it
        m  = what.content.root

        m.find("des:header").each do |h|
          return false unless header h
        end

        if ignore_name
          # if only one parameter, ignore the name
          @numparams = m.find("count(//des:parameter)").to_i
        end  

        m.find("des:*[not(name()='header')]").each do |p|
          return false unless send p.qname.to_s, p
        end

        @mist.count == @mistp
        #}}}
      end

      def parameter(a)
        #{{{
        return false if @mistp >= @mist.length
        b = @mist[@mistp]

        if b.class == Riddl::Parameter::Simple && (a.attributes['fixed'] || a.attributes['type'])
          b.name = a.attributes['name'] if @numparams == 1
          if (b.name == a.attributes['name'] || a.attributes['name'] == '*')
            @mistp += 1
            return match_simple(a,b.value)
          end
        end
        if b.class == Riddl::Parameter::Complex && a.attributes['mimetype']
          b.name = a.attributes['name'] if @numparams == 1
          if (b.name == a.attributes['name'] || a.attributes['name'] == '*') && match_mimetype(a,b)
            if a.attributes['handler']
              if Riddl::Handlers::handlers[a.attributes['handler']]
                success = Riddl::Handlers::handlers[a.attributes['handler']].handle(b.value,a.children.map{|e|e.dump}.join)
                b.value.rewind if b.value.respond_to?(:rewind)
                if success
                  @mistp += 1
                  return true
                end  
              else
                # handler not found leads to an error
                return false
              end  
            else
              @mistp += 1
              return true
            end  
          end
        end  
        false
        #}}}
      end
      private :parameter
      
      def oneOrMore(a)
        #{{{
        tistp = @mistp
        ncounter = 0
        begin
          counter,length = traverse_simple(a,true)
          ncounter += 1 if counter == length
        end while counter == length && @mistp < @mist.length
        if ncounter > 0 
          true
        else  
          @mistp = tistp
          false
        end  
        #}}}
      end

      def zeroOrMore(a)
        #{{{
        begin
          counter,length = traverse_simple(a,true)
        end while counter == length && @mistp < @mist.length 
        true
        #}}}
      end

      def choice(a)
        #{{{
        a.find("des:*").each do |p|
          return true if send p.qname.to_s, p
        end
        false
        #}}}
      end  
      
      def group(a)
        #{{{
        tistp = @mistp
        success = true
        a.find("des:*").each do |p|
          unless send p.qname.to_s, p
            success = false
            break
          end
        end
        if success
          true
        else  
          @mistp = tistp
          false
        end  
        #}}}
      end  

      def optional(a)
        #{{{
        return true if @mistp >= @mist.length

        tistp = @mistp
        counter, length = traverse_simple(a,true)

        if counter == 0 || counter == length
          true
        else  
          @mistp = tistp
          false
        end
        #}}}
      end

      def header(a)
        #{{{
        name = a.attributes['name'].upcase.sub(/\-/,'_')
        if @headp[name]
          return match_simple(a,@headp[name])
        end
        false
        #}}}
      end
      private :header

      def traverse_simple(a,single_optional_protection=false)
        #{{{
        tistp = @mistp
        nodes = a.find("des:*")
        counter = 0
        lastname = ''
        nodes.each do |p|
          lastname = p.qname.to_s 
          counter += 1 if send lastname, p
        end
        if single_optional_protection && lastname == 'optional' && tistp == @mistp
          [0,-1]
        else  
          [counter,nodes.length]
        end 
        #}}}
      end
      
      def match_simple(a,b)
        #{{{
        if a.attributes['fixed']
          a.attributes['fixed'] == b
        else  
          value = XML::Smart::string("<check/>")
          value.root.text = b
          type = XML::Smart::string(CHECK)
          data = type.root.children[0]
          data.attributes['type'] = a.attributes['type']
          data.add a.children
          value.validate_against type
        end  
        #}}}
      end
      private :match_simple

      def match_mimetype(a,b)
        if (a.attributes['mimetype'] == '*' || b.mimetype == a.attributes['mimetype'])
          true
        else
          ma = a.attributes['mimetype'].split('/')
          mb = b.mimetype.split('/')
          if ma.length == 2 && mb.length == 2 && ((ma[0] == mb[0] && ma[1] == '*') || (ma[1] == mb[1] && ma[0] == '*'))
            true
          else
            false
          end  
        end
      end
      private :match_mimetype

    end  
  end    
end
