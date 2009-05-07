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
            tpath = path == "/" ? '/' : path.gsub(/\/([^{}\/]+)/,"/des:resource[@relative=\"\\1\"]").gsub(/\/\{\}/,"des:resource[not(@relative)]").gsub(/\/+/,'/')
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
            raise PathError
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
              raise OccursError, "input is parsed, description still has necessary elements" if sol.nil? and !ist.nil?
              if ist.nil? and !sol.nil?
                until sol.nil?
                  csol += 1
                  sol = msol[csol]
                  raise OccursError, "ERROR description is parsed, input still has elements" if sol.attributes['occurs'].nil? || sol.attributes['occurs'] == '+'
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
                      raise OccursError, "input has not enough parameters #{sol.name}"
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
                    raise OccursError, "#{sol.attributes['name']} is not a desired input"
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

            h_ifield = {}; h_pfield = {}
            h_ofield = {}; h_afield = {}; h_rfield = {}
            h_cfield = {}
            res.find("des:get|des:put|des:delete|des:post|des:request").each do |mt|
              mn = (mt.attributes['type'].nil? ? mt.name.to_s : mt.attributes['type'])

              h_ifield[mn] ||= {}; h_pfield[mn] ||= {}
              h_ofield[mn] ||= []; h_afield[mn] ||= []; h_rfield[mn] ||= []
              h_cfield[mn] ||= 0

              a = mt.attributes
              if !a['in'].nil? && a['in'] != '*'
                h_ifield[mn][a['in']] ||= 0
                h_ifield[mn][a['in']] += 1
              end
              if !a['pass'].nil? && a['pass'] != '*'
                h_pfield[mn][a['pass']] ||= 0
                h_pfield[mn][a['pass']] += 1
              end
              h_ofield[mn] << a['out'] unless a['out'].nil?
              h_afield[mn] << a['add'] unless a['add'].nil?
              h_rfield[mn] << a['remove'] unless a['remove'].nil?
              h_cfield[mn] += 1 if !a['remove'].nil? || !a['add'].nil? || a['in'] == '*' || a['pass'] == '*'
            end

            h_ifield.each do |mn,ifield|
              messages += check_multi_fields(ifield,"#{tpath} -> #{mn}","in")
            end
            h_pfield.each do |mn,pfield|
              messages += check_multi_fields(pfield,"#{tpath} -> #{mn}","pass")
            end
            h_ofield.each do |mn,ofield|
              messages += check_fields(ofield,"#{tpath} -> #{mn}","out")
            end  
            h_afield.each do |mn,afield|
              messages += check_fields(afield,"#{tpath} -> #{mn}","add")
            end  
            h_rfield.each do |mn,rfield|
              messages += check_fields(rfield,"#{tpath} -> #{mn}","remove")
            end  
            h_cfield.each do |mn,cfield|
              puts "#{tpath} -> #{mn}: more than one catchall (*) operation is not allowed." if cfield > 1
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
