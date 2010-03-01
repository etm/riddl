class Execution
  @@error_message = ""
  def self.check_syntax(service, interface)
    @@error_message = ""
    service.find("//service:methods/*", {"service"=>"http://rescue.org/ns/service/0.2"}).each do |execution|
      method_name = execution.name.name
      #puts "Checking Execution within service-details/methods/#{method_name}/execution"
      # Cheking if any input-message-parameter is referred as input for an activity that is not part of the input-message
      execution.find("//service:#{method_name}/service:execution/descendant::exec:input", 
                {"exec"=>"http://rescue.org/ns/execution/0.2", "service"=>"http://rescue.org/ns/service/0.2"}).each do |input|
        message_param = nil
        if input.attributes.include?("message-parameter")
          message_param = interface.find("/group:interface/group:methods/group:method[@name='#{method_name}']/group:input-message/rng:element[@name='#{input.attributes.get_attr("message-parameter")}']", 
                          {"group"=>"http://rescue.org/ns/group/0.2", "rng" => "http://relaxng.org/ns/structure/1.0"}).first
        else
          message_param = execution.find("//exec:context[@id='#{input.attributes.get_attr("context")}']", 
                          {"exec"=>"http://rescue.org/ns/execution/0.2", "rng" => "http://relaxng.org/ns/structure/1.0"}).first
        end
        if message_param == nil
          @@error_message = @@error_message + "========== Input named \"#{input.attributes.get_attr("name")}\" within method \"#{method_name}\" referes to an element which is not part of the input-method\n"
        end
      end
      # Cheking if every output-message-parameter is used at least once as an output of an activity
      m = interface.find("//group:method[@name='#{method_name}']/group:output-message/*", 
                    {"group"=>"http://rescue.org/ns/group/0.2", "rng" => "http://relaxng.org/ns/structure/1.0"}).first
      xpath = "//group:method[@name='#{method_name}']/group:output-message/descendant::rng:element" if m.name.name == "element"
      xpath = "//group:method[@name='#{method_name}']/group:output-message/rng:zeroOrMore/rng:element/descendant::rng:element" if m.name.name == "zeroOrMore"
      interface.find(xpath, 
                    {"group"=>"http://rescue.org/ns/group/0.2", "rng" => "http://relaxng.org/ns/structure/1.0"}).each do |output|
        message_param = nil
        message_param = execution.find("//service:#{method_name}/descendant::exec:output[@message-parameter='#{output.attributes.get_attr("name")}']",
                        {"service"=>"http://rescue.org/ns/service/0.2", "exec" => "http://rescue.org/ns/execution/0.2"}).first
        if message_param == nil
          @@error_message = @@error_message + "========== Output named \"#{output.attributes.get_attr("name")}\" is not set within method \"#{method_name}\"\n"
        end
      end
      # Checking if any place-holder is used within a service-uri that is not defined either in the input-message or as a context-variable
      execution.find("//service:#{method_name}/descendant::exec:endpoint",
                    {"exec"=>"http://rescue.org/ns/execution/0.2", "service"=>"http://rescue.org/ns/service/0.2"}).each do |endpoint|
        value = endpoint.text
        rx = Regexp.new('\{[^\}]*\}')
        value.scan(rx).each do |placeholder|
          context = execution.find("//service:#{method_name}/descendant::exec:context[@id='#{placeholder[1..-2]}']",
                           {"exec"=>"http://rescue.org/ns/execution/0.2", "service"=>"http://rescue.org/ns/service/0.2"}).first 
          input = interface.find("//group:method[@name='#{method_name}']/group:input-message/descendant::rng:element[@name='#{placeholder[1..-2]}']",
                           {"group"=>"http://rescue.org/ns/group/0.2", "rng" => "http://relaxng.org/ns/structure/1.0"}).first
          if context == nil && input == nil
            @@error_message = @@error_message + "========== Placeholder named \"#{placeholder[1..-2]}\" is not available within method \"#{method_name}\"\n"
          end
        end
      end
    end
    @@error_message == ""
  end

  def self.error()
    @@error_message
  end
end

