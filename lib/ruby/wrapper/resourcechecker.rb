module Riddl
  class Wrapper
    class ResourceChecker
      def initialize(doc)
        @doc = doc
      end

      def check
        check_rec_resources(@doc.find("/des:description/des:resource"))
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
          h_ofield = {}; h_tfield = {}
          h_cfield = {}
          res.find("des:get|des:put|des:delete|des:post|des:request").each do |mt|
            mn = (mt.attributes['type'].nil? ? mt.qname.to_s : mt.attributes['type'])

            h_ifield[mn] ||= {}; h_pfield[mn] ||= {}
            h_ofield[mn] ||= []; h_tfield[mn] ||= []
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
            h_tfield[mn] << a['transformation'] unless a['transformation'].nil?
            h_cfield[mn] += 1 if !a['transformation'].nil? || a['in'] == '*' || a['pass'] == '*'
          end

          h_ifield.each do |mn,ifield|
            messages += check_multi_fields(ifield,"#{tpath} -> #{mn}","in")
          end
          h_pfield.each do |mn,pfield|
            messages += check_multi_fields(pfield,"#{tpath} -> #{mn}","pass")
          end
          h_ofield.each do |mn,ofield|
            messages += check_fields(ofield,"#{tpath} -> #{mn}","out","message")
          end  
          h_tfield.each do |mn,tfield|
            messages += check_fields(tfield,"#{tpath} -> #{mn}","transformation","transformation")
          end  
          h_cfield.each do |mn,cfield|
            messages << "#{tpath} -> #{mn}: more than one catchall (*) operation is not allowed." if cfield > 1
          end
          messages += check_rec_resources(res.find("des:resource"),tpath)
        end
        messages
        #}}}
      end
      private :check_rec_resources

      def check_fields(field, what, name, sname)
        #{{{
        messages = []
        field.compact.each do |k|
          if @doc.find("/des:description/des:#{sname}[@name='#{k}']").empty?
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
          if @doc.find("/des:description/des:message[@name='#{k}']").empty?
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
  end
end
