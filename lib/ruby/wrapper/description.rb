require File.expand_path(File.dirname(__FILE__) + '/description/resource')
require File.expand_path(File.dirname(__FILE__) + '/description/request')
require File.expand_path(File.dirname(__FILE__) + '/description/message_and_transformation')

module Riddl
  class Wrapper
    class Description
      def initialize(riddl)
        des = riddl.find("/dec:declaration/dec:interface[@name=\"#{lname}\"]/des:description").first
        desres = des.find("des:resource").first
        if apply_to.empty?
          til.add_description(des,desres,"/",index,lname,block)
        else
          apply_to.each do |at|
            til.add_description(des,desres,at.to_s,index,lname,block)
          end
        end
      end
    end

  end
end
