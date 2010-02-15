module Riddl
  class Wrapper
    class MessageParser
      def initialize(params,heads)
        #{{{
        @mist = params
        @mistp = 0
        @headp = {}
        heads.each do |k,v|
          @headp[k.upcase.sub(/\-/,'_')] = v
        end
        @headers = []

        @numparams = 0
        #}}}
      end

      attr_reader :headers

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
          return false unless send p.name.to_s, p
        end
        true
        #}}}
      end

      def parameter(a)
        #{{{
        return false if @mistp >= @mist.length
        b = @mist[@mistp]

        if b.class == Riddl::Parameter::Simple && (a.attributes['fixed'] || a.attributes['type'])
          b.name = a.attributes['name'] if @numparams == 1
          if b.name == a.attributes['name']
            @mistp += 1
            return match_simple(a,b.value)
          end
        end
        if b.class == Riddl::Parameter::Complex && a.attributes['mimetype']
          b.name = a.attributes['name'] if @numparams == 1
          if b.name == a.attributes['name'] && (a.attributes['mimetype'] == '*' || b.mimetype == a.attributes['mimetype'])
            if a.attributes['handler']
              if Riddl::Handlers::handlers[a.attributes['handler']]
                @mistp += 1
                return Riddl::Handlers::handlers[a.attributes['handler']].handle(b.value,a.children.map{|e|e.dump}.join)
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
          return true if send p.name.to_s, p
        end
        false
        #}}}
      end  
      
      def group(a)
        #{{{
        tistp = @mistp
        success = true
        a.find("des:*").each do |p|
          unless send p.name.to_s, p
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
        tistp = @mistp
        counter, length = traverse_simple(a)
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
          re =  match_simple(a,@headp[name])
          @headers << Riddl::Header.new(name,@headp[name]) if re
          return re
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
          lastname = p.name.to_s 
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
          a.children.each { |e| data.add(e) }
          value.validate_against type
        end  
        #}}}
      end
      private :match_simple
    end  
  end    
end
