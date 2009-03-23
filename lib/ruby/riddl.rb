require 'xml/smart'
  
class Riddl < XML::Smart
  def self::open(name)
    doc = superclass::open(name)
    doc.xinclude!
    doc.namespaces = {
      'dec' => "http://riddl.org/ns/declaration/1.0",
      'des' => "http://riddl.org/ns/description/1.0"
    }
    (class << doc; self; end).class_eval do
      def validate!
        return self.validate_against(XML::Smart.open("#{File.dirname(__FILE__)}/../../ns/description-1_0.rng")) if @description
        return self.validate_against(XML::Smart.open("#{File.dirname(__FILE__)}/../../ns/declaration-1_0.rng")) if @declaration
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
            res.find("des:#{mt}").each do |e|
              a = e.attributes
              unless a['in'].nil?
                ifield[a['in']] ||= 0
                ifield[a['in']] += 1
              end  
              unless a['pass'].nil?
                pfield[a['pass']] ||= 0
                pfield[a['pass']] += 1
              end   
              ofield << a['out'] unless a['out'].nil?
              afield << a['add'] unless a['add'].nil?
              rfield << a['remove'] unless a['remove'].nil?
            end
            what = "#{path.gsub(/(.)\/$/,'\1')} -> #{mt}"
            messages += check_multi_fields(ifield,what,"in")
            messages += check_multi_fields(pfield,what,"pass")
            messages += check_fields(ofield,what,"out")
            messages += check_fields(afield,what,"add")
            messages += check_fields(rfield,what,"remove")
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
end
