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
      define_method 'validate!' do 
        return self.validate_against(XML::Smart.open("#{File.dirname(__FILE__)}/../../ns/description-1_0.rng")) if @description
        return self.validate_against(XML::Smart.open("#{File.dirname(__FILE__)}/../../ns/declaration-1_0.rng")) if @declaration
        nil
      end

      define_method '__riddl_init' do
        qname = self.root.name
        @description = qname.namespace == "http://riddl.org/ns/description/1.0" && qname.name ==  "description"
        @declaration = qname.namespace == "http://riddl.org/ns/declaration/1.0" && qname.name ==  "declaration"
      end

      define_method 'declaration?' do
        @declaration 
      end
      define_method 'description?' do
        @description 
      end

      define_method 'valid_resources?' do
        @description ? check_rec_resources(self.find("/des:description/des:resource")) : []
      end

      def check_rec_resources(res,path="")
        messages = []
        res.each do |res|
          tpath = res.attributes['relative'].nil? ? '{}' : res.attributes['relative']
          %w{post get put delete}.each do |mt|
            ifield = {}
            ofield = []
            res.find("des:#{mt}").each do |e|
              ifield[e.attributes['in']] ||= 0
              ifield[e.attributes['in']] += 1
              ofield << e.attributes['out']
            end
            ifield.each do |k,v|
              if self.find("/des:description/des:message[@name='#{k}']").empty?
                messages << "#{path}/#{tpath} -> #{mt}: input message '#{k}' not found."
              end unless k == '*'
              if v > 1
                messages << "#{path}/#{tpath} -> #{mt}: input message '#{k}' is allowed to occur only once."
              end
            end
            ofield.compact.each do |k|
              if self.find("/des:description/des:message[@name='#{k}']").empty?
                messages << "#{path}/#{tpath} -> #{mt}: output message '#{k}' not found."
              end unless k == '*'
            end
          end
          messages += check_rec_resources(res.find("des:resource"),path + "/" + tpath)
        end
        messages
      end

    end
    doc.__riddl_init 
    doc
  end
end
