require 'rubygems'
gem 'ruby-xml-smart', '>= 0.2.0.1'
require 'xml/smart'
require File.expand_path(File.dirname(__FILE__) + '/wrapper/description')
require File.expand_path(File.dirname(__FILE__) + '/wrapper/declaration')
require File.expand_path(File.dirname(__FILE__) + '/wrapper/messageparser')
require File.expand_path(File.dirname(__FILE__) + '/wrapper/resourcechecker')
require File.expand_path(File.dirname(__FILE__) + '/wrapper/layerchecker')
require File.expand_path(File.dirname(__FILE__) + '/handlers')

module Riddl
  class Wrapper
    #{{{
    VERSION_MAJOR = 1
    VERSION_MINOR = 0
    VERSION = "#{VERSION_MAJOR}.#{VERSION_MINOR}"
    DESCRIPTION = "http://riddl.org/ns/description/#{VERSION}"
    DECLARATION = "http://riddl.org/ns/declaration/#{VERSION}"
    DESCRIPTION_FILE = "#{File.dirname(__FILE__)}/ns/description-#{VERSION_MAJOR}_#{VERSION_MINOR}.rng"
    DECLARATION_FILE = "#{File.dirname(__FILE__)}/ns/declaration-#{VERSION_MAJOR}_#{VERSION_MINOR}.rng"
    COMMON = "datatypeLibrary=\"http://www.w3.org/2001/XMLSchema-datatypes\" xmlns=\"#{DESCRIPTION}\" xmlns:xi=\"http://www.w3.org/2001/XInclude\""
    CHECK = "<element name=\"check\" datatypeLibrary=\"http://www.w3.org/2001/XMLSchema-datatypes\" xmlns=\"http://relaxng.org/ns/structure/1.0\"><data/></element>"
    #}}}

    def initialize(name,protocol="GET")
      #{{{
      @doc = XML::Smart.open(name)
      @doc.xinclude!
      @doc.namespaces = {
        'des' => DESCRIPTION,
        'dec' => DECLARATION
      }
      qname = @doc.root.name
      @is_description = qname.namespace == DESCRIPTION && qname.name ==  'description'
      @is_declaration = qname.namespace == DECLARATION && qname.name ==  'declaration'
      @declaration = @description = nil
      #}}}
    end

    def declaration
      #{{{
      if @is_declaration
        @declaration = Riddl::Wrapper::Declaration.new(@doc)
      end
      @declaration
      #}}}
    end
      
    def description
      #{{{
      if @is_description
        @description = Riddl::Wrapper::Description.new(@doc)
      end
      @description
      #}}}
    end  

    def get_message(path,operation,params,headers)
      #{{
      description
      declaration
      
      req = @description.get_resource(path).requests if @is_description
      req = @declaration.get_resource(path).composition if @is_declaration

      mp = MessageParser.new(params,headers)
      if req.has_key?(operation)
        r = req[operation][0] if @is_description
        r = req[operation].result if @is_declaration
        r.select{|o|o.class==Riddl::Wrapper::Description::RequestInOut}.each do |o|
          return o.in, o.out if mp.check(o.in)
        end
        r.select{|o|o.class==Riddl::Wrapper::Description::RequestStarOut}.each do |o|
          return Riddl::Wrapper::Description::Star.new, o.out
        end
        r.select{|o|o.class==Riddl::Wrapper::Description::RequestTransformation}.each do |o|
          # TODO guess structure from input, create new output structure
          return Riddl::Wrapper::Description::Star.new, Riddl::Wrapper::Description::Star.new
        end
        r.select{|o|o.class==Riddl::Wrapper::Description::RequestPass}.each do |o|
          return Riddl::Wrapper::Description::Star.new, Riddl::Wrapper::Description::Star.new
        end
      end  
      return [nil,nil]
      #}}}
    end

    def check_message(params,headers,message)
      description
      declaration
      #{{{
      return true if message.class == Riddl::Wrapper::Description::Star
      mp = MessageParser.new(params,headers)
      mp.check(message)
      #}}}
    end

    def validate!
      #{{{
      if @is_description
        xval = @doc.validate_against(XML::Smart.open(DESCRIPTION_FILE))
        xchk = ResourceChecker.new(@doc).check.empty?
        return xval && xchk
      end
      if @is_declaration
        xval = @doc.validate_against(XML::Smart.open(DECLARATION_FILE))
        xchk = LayerChecker.new(@doc).check.empty?
        return xval && xchk
      end
      nil
      #}}}
    end

    def load_necessary_handlers!
      #{{{
      @doc.find("//des:parameter/@handler").map{|h|h.to_s}.uniq.each do |h|
        if File.exists?(File.dirname(__FILE__) + '/handlers/' + File.basename(h) + ".rb")
          require File.expand_path(File.dirname(__FILE__) + '/handlers/' + File.basename(h))
        end
      end
      #}}}
    end

    def paths
      #{{{
      description
      declaration
      tmp = []
      tmp = @description.paths if @is_description 
      tmp = @declaration.paths if @is_declaration
      tmp.map do |t|
        [t[0],Regexp.new("^" + t[0].gsub(/\{\}/,"[^/]+") + (t[1] ? '' : '$'))]
      end
      #}}}
    end

    def declaration?; @is_declaration; end
    def description?; @is_description; end
  end
end
