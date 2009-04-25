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
            tpath = path == "/" ? '' : path.gsub(/\/([^{}\/]+)/,"/des:resource[@relative=\"\\1\"]").gsub(/\/\{\}/,"des:resource[not(@relative)]").gsub(/\/+/,'/')
            tpath = "/des:description/des:resource" + tpath + "des:" + operation
            self.find(tpath + "[@in and not(@in='*')]").each do |o|
              return o.attributes['in'], o.attributes['out'] if check_message(o.attributes['in'],params)
            end
            self.find(tpath + "[@pass and not(@pass='*')]").each do |o|
              return o.attributes['pass'], o.attributes['pass'] if check_message(o.attributes['pass'],params)
            end
            self.find(tpath + "[@in and @in='*']").each do
              return "*", o.attributes['out']
            end
            self.find(tpath + "[@add or @remove]").each do
              return "*", "*" # TODO guess structure from input, create new output structure
            end
            self.find(tpath + "[@pass and @pass='*']").each do
              return "*", "*"
            end
            raise "Error wrong path"
          end
          nil
          #}}}
        end

        def check_message(name,mist)
          #{{{
          self.find("/des:description/des:message[@name='#{name}']").each do |m|
            msol = m.children
            cist = 0
            csol = 0
            pcounter = nil
            loop do
              sol = msol[csol]
              ist = mist[cist]
              break if ist.nil? and sol.nil?
              raise "ERROR sol zuende, ist nicht" if sol.nil? and !ist.nil?
              if ist.nil? and !sol.nil?
                until sol.nil?
                  csol += 1
                  sol = msol[csol]
                  raise "ERROR ist zuende, sol nicht" if sol.attributes['occurs'].nil? || sol.attributes['occurs'] == '+'
                end
                break
              end  
              case sol.attributes['occurs']
                when '?'
                  cist += 1 if identical(sol,ist)
                  csol += 1
                  next
                when '*'
                  if identical(sol,ist)
                    cist += 1
                  else  
                    csol += 1
                  end  
                  next
                when '+'
                  if identical(sol,ist)
                    cist += 1
                    pcounter ||= 0
                    pcounter += 1
                  else
                    if pcounter.nil?
                      raise "ERROR nicht genug plus"
                    else  
                      pcounter = nil
                      csol += 1
                    end  
                  end  
                else
                  if identical(sol,ist)
                    csol += 1
                    cist += 1
                  else
                    raise "ERROR nicht gefunden"
                  end  
              end  
            end
          end
          #}}}
        end

        def identical(a,b)
          b.name == a.attributes['name']
          #TODO
          #wenn mimetype check handler
          #wenn type relaxng bauen un checken
        end
        private :identical

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

end
