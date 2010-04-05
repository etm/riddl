module Riddl
  class Wrapper
    class Description < WrapperUtils

      class HashBase
        #{{{
        def initialize(layer,name,type,content=nil)
          @name = name
          @hash = nil
          if layer.nil?
            @content = content
          else  
            tempA = layer.find("des:#{type}[@name='#{name}']").first
            tempB = tempA.to_doc
            if layer.namespaces[nil] && tempA.namespaces.to_a.empty?
              tempB.root.namespaces[nil] = layer.namespaces[nil]
            end  
            tempB.root.find("@name").delete_all!
            @content = tempB.root.to_doc
            @content.namespaces = {
              'des' => Riddl::Wrapper::DESCRIPTION,
              'dec' => Riddl::Wrapper::DECLARATION
            }
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

      class Transformation < HashBase
        #{{{
        def initialize(layer,name,xml=nil)
          super layer,name,:transformation,xml
        end
        def self.new_from_xml(name,xml)
          Transformation.new(nil,name,xml)
        end
        #}}}
      end

      class Message < HashBase
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
                  raise "TODO"
                when 'add_before':
                  raise "TODO"
                when 'add_after':
                  raise "TODO"
                when 'add_as_first':
                  t = ret.content.root 
                  n = t.find("header[last()]").first
                  if n.nil?
                    m = t.find("*[not(header)]").first
                    if m.nil?
                      t.add(e.children)
                    else  
                      m.add_before(e.children)
                    end
                  else  
                    n.add_after(e.children)
                  end  
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

      class Star
        #{{{
        def name; "*"; end
        #}}}
      end

    end
  end
end
