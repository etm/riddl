require 'rubygems'
gem 'ruby-xml-smart', '>= 0.2.0.1'
require 'xml/smart'
require ::File.dirname(__FILE__) + '/file/messageparser'
require ::File.dirname(__FILE__) + '/file/resourcechecker'
require ::File.dirname(__FILE__) + '/file/layerchecker'
require ::File.dirname(__FILE__) + '/handlers'

$iii = 0

module Riddl
  class File
    #{{{
    VERSION_MAJOR = 1
    VERSION_MINOR = 0
    VERSION = "#{VERSION_MAJOR}.#{VERSION_MINOR}"
    DESCRIPTION = "http://riddl.org/ns/description/#{VERSION}"
    DECLARATION = "http://riddl.org/ns/declaration/#{VERSION}"
    DESCRIPTION_FILE = "#{::File.dirname(__FILE__)}/ns/description-#{VERSION_MAJOR}_#{VERSION_MINOR}.rng"
    DECLARATION_FILE = "#{::File.dirname(__FILE__)}/ns/declaration-#{VERSION_MAJOR}_#{VERSION_MINOR}.rng"
    COMMON = "datatypeLibrary=\"http://www.w3.org/2001/XMLSchema-datatypes\" xmlns=\"#{DESCRIPTION}\" xmlns:xi=\"http://www.w3.org/2001/XInclude\""
    CHECK = "<element name=\"check\" datatypeLibrary=\"http://www.w3.org/2001/XMLSchema-datatypes\" xmlns=\"http://relaxng.org/ns/structure/1.0\"><data/></element>"
    #}}}

    def initialize(name)
      #{{{
      @doc = XML::Smart.open(name)
      @doc.xinclude!
      @doc.namespaces = {
        'des' => DESCRIPTION,
        'dec' => DECLARATION
      }
      qname = @doc.root.name
      @description = qname.namespace == DESCRIPTION && qname.name ==  'description'
      @declaration = qname.namespace == DECLARATION && qname.name ==  'declaration'
      #}}}
    end

    def declaration
      Riddl::File::Declaration.new(@doc)
    end

    def get_message(path,operation,params,headers)
      #{{{
      if description?
        tpath = path == "/" ? '/' : path.gsub(/\/([^{}\/]+)/,"/des:resource[@relative=\"\\1\"]").gsub(/\/\{\}/,"/des:resource[not(@relative)]").gsub(/\/+/,'/')
        tpath = "/des:description/des:resource" + tpath + "des:" + operation + "|/des:description/des:resource" + tpath + "des:request[@method='#{operation}']"
        mp = MessageParser.new(@doc,params,headers)
        @doc.find(tpath + "[@in and not(@in='*')]").each do |o|
          return o.attributes['in'], o.attributes['out'] if mp.check(o.attributes['in'])
        end
        @doc.find(tpath + "[@pass and not(@pass='*')]").each do |o|
          return o.attributes['pass'], o.attributes['pass'] if mp.check(o.attributes['pass'])
        end
        @doc.find(tpath + "[@in and @in='*']").each do |o|
          return "*", o.attributes['out']
        end
        @doc.find(tpath + "[@add or @remove]").each do
          return "*", "*" # TODO guess structure from input, create new output structure
        end
        @doc.find(tpath + "[@pass and @pass='*']").each do
          return "*", "*"
        end
        [nil,nil]
      end
      nil
      #}}}
    end

    def check_message(params,headers,name)
      mp = MessageParser.new(@doc,params,headers)
      mp.check(name)
    end  

    def validate!
      #{{{
      return @doc.validate_against(XML::Smart.open(DESCRIPTION_FILE)) if @description
      return @doc.validate_against(XML::Smart.open(DECLARATION_FILE)) if @declaration
      nil
      #}}}
    end

    def load_necessary_handlers!
      #{{{
      @doc.find("//des:parameter/@handler").map{|h|h.to_s}.uniq.each do |h|
        if ::File.exists?(::File.dirname(__FILE__) + '/handlers/' + ::File.basename(h) + ".rb")
          require ::File.dirname(__FILE__) + '/handlers/' + ::File.basename(h)
        end
      end
      #}}}
    end

    def paths
      #{{{
      (@description ? get_paths(@doc.find("/des:description/des:resource")) : []).map do |p|
        [p,Regexp.new("^" + p.gsub(/\{\}/,"[^/]+") + "$")]
      end
      #}}}
    end

    def get_paths(res,path='')
      #{{{
      tpath = []
      res.each do |res|
        tpath << xpath = if path == ''
          ['/',false]
        else
          [res.attributes['relative'].nil? ? path.dup << '{}/' : path.dup << res.attributes['relative'] + '/',res.attributes['recursive'].nil? ? false : true]
        end
        tpath += get_paths(res.find("des:resource[@relative]"),xpath) 
        tpath += get_paths(res.find("des:resource[not(@relative)]"),xpath) 
      end  
      tpath
      #}}}
    end
    private :get_paths

    def declaration?; @declaration; end
    def description?; @description; end
    def valid_resources?
      @description ? ResourceChecker.new(@doc).check : []
    end
    def valid_layers?
      @declaration ? LayerChecker.new(@doc).check : []
    end
  end
end
