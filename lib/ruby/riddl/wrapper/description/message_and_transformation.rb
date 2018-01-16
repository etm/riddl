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
            puts layer.dump
            puts "des:#{type}[@name='#{name}']"

            @content = layer.find("des:#{type}[@name='#{name}']").first.to_doc
            @content.root.find("@name").delete_all!
            @content.register_namespace 'des', Riddl::Wrapper::DESCRIPTION
          end
          update_hash!
        end
        def update_hash!
          # TODO too simple
          hb = @content.root.to_doc
          hb.register_namespace 'des', Riddl::Wrapper::DESCRIPTION
          hb.unformated = true
          hb.find("//comment()").delete_all!
          hb.find("//des:parameter/*").delete_all!
          hb.find("//text()").delete_all!
          hb.find("//des:header/*").delete_all!
          hb.find("//des:parameter/@handler").delete_all!
          # hb.find("//des:parameter/@mimetype").each { |e| e.value = '' }
          hb.root.namespaces.delete_all!
          @hash_base = hb
          @hash      = hb.serialize.hash
        end
        def traverse?(other)
          if other.name.nil?
            false
          else
            paths = self.hash_base.find("//des:parameter").map{ |e| e.path + "/@name" }
            hb2 = XML::Smart::string(other.hash_base.serialize)
            hb2.register_namespace 'des', Riddl::Wrapper::DESCRIPTION
            hb2.unformated = true

            paths.each do |p|
              (hb2.find(p).first.value = '*') rescue nil
            end

            self.hash_base.serialize.hash == hb2.serialize.hash
          end
        end
        attr_reader :name, :content, :hash, :hash_base
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
              case e.qname.name
                when 'add_header'
                  raise "TODO"
                when 'add_before'
                  raise "TODO"
                when 'add_after'
                  raise "TODO"
                when 'add_as_first'
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
                when 'add_as_last'
                  ret.content.root.add(e.children)
                  ret.update_hash!
                when 'remove_each'
                  ret.content.find("parameter[@name=\"#{e.attributes['name']}\"]").delete_all!
                when 'remove_first'
                  if e.attributes['name']
                    case e.attributes['type']
                      when 'parameter', nil
                        node = ret.content.find("//parameter[@name=\"#{e.attributes['name']}\"]").first
                        opt = node.add_before("optional")
                        opt.add(node)
                      when 'header'
                        ret.content.find("header[@name=\"#{e.attributes['name']}\"]").delete_all!
                    end
                  else
                    case e.attributes['type']
                      when 'parameter', nil
                        ret.content.find("//parameter[first()]").delete_all!
                      when 'header'
                        ret.content.find("//header[first()]").delete_all!
                    end
                  end
                when 'remove_last'
                  if e.attributes['name']
                    case e.attributes['type']
                      when 'parameter', nil
                        node = ret.content.find("//parameter[@name=\"#{e.attributes['name']}\"]").last
                        opt = node.add_before("optional")
                        opt.add(node)
                      when 'header'
                        ret.content.find("header[@name=\"#{e.attributes['name']}\"]").delete_all!
                    end
                  else
                    case e.attributes['type']
                      when 'parameter', nil
                        ret.content.find("//parameter[last()]").delete_all!
                      when 'header'
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
