module Riddl
  class File
    class Description
      class Base
        #{{{
        def initialize(layer,name,type,content=nil)
          @name = name
          @hash = nil
          if layer.nil?
            @content = content
          else  
            @content = layer.find("des:#{type}[@name='#{name}']").first.to_doc
            @content.find("/#{type}/@name").delete_all!
          end  
          update_hash!
        end
        def update_hash!
          # TODO too simple
          @hash = @content.to_s.hash
        end
        def traverse?(other)
          other.name.nil? ? false : (self.hash == other.hash)
        end
        attr_reader :name, :content, :hash
        #}}}
      end

      class Transformation < Riddl::File::Description::Base
        #{{{
        def initialize(layer,name,xml=nil)
          super layer,name,:transformation,xml
        end
        def self.new_from_xml(name,xml)
          Transformation.new(nil,name,xml)
        end
        #}}}
      end

      class Message < Riddl::File::Description::Base
        #{{{
        def initialize(layer,name)
          super layer,name,:message
        end
        def initialize_copy(o)
          @content = @content.dup 
        end
        def transform(trans)
          ret = self.dup
          unless trans.name.nil?
            trans.content.root.children.each do |e|
              case e.name.name
                when 'add_header':
                when 'add_before':
                when 'add_after':
                when 'add_as_first':
                when 'add_as_last':
                  ret.content.root.add(e.children)
                  ret.update_hash!
                when 'remove_each':
                  ret.content.find("parameter[@name=\"#{e.attributes['name']}\"]").delete_all!
                when 'remove_first':
                  if e.attributes['name']
                    case e.attributes['type']
                      when 'parameter', nil:
                        node = ret.content.find("//parameter[@name=\"#{e.attributes['name']}\"]").first
                        opt = node.add_before("optional")
                        opt.add(node)
                      when 'header':
                        ret.content.find("header[@name=\"#{e.attributes['name']}\"]").delete_all!
                    end    
                  else
                    case e.attributes['type']
                      when 'parameter', nil:
                        ret.content.find("//parameter[first()]").delete_all!
                      when 'header':
                        ret.content.find("//header[first()]").delete_all!
                    end    
                  end
                when 'remove_last':
                  if e.attributes['name']
                    case e.attributes['type']
                      when 'parameter', nil:
                        node = ret.content.find("//parameter[@name=\"#{e.attributes['name']}\"]").last
                        opt = node.add_before("optional")
                        opt.add(node)
                      when 'header':
                        ret.content.find("header[@name=\"#{e.attributes['name']}\"]").delete_all!
                    end    
                  else
                    case e.attributes['type']
                      when 'parameter', nil:
                        ret.content.find("//parameter[last()]").delete_all!
                      when 'header':
                        ret.content.find("//header[last()]").delete_all!
                    end    
                  end
              end  
            end  
          end  
          return ret
        end
        #}}}
      end
    end
  end
end
