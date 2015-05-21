class Puppet::Provider::Asadmin < Puppet::Provider

  # keeps the state of 
  @@up_and_running = false
  
  def asadmin_exec(passed_args,ignore_previous_check=false)

    if ignore_previous_check == true
      @@up_and_running = false
    end

    # Use dashost if present
    if @resource.parameters.include?(:dashost)
      host = @resource[:dashost]
    end
    
    # Use dasport first, and then fallback to portbase
    if @resource.parameters.include?(:dasport)
      port = @resource[:dasport]
    else
      port = @resource[:portbase].to_i + 48
    end


    # Compile an array of command args
    args = Array.new
    args << '--host' << host if host && !host.nil?
    args << '--port' << port.to_s
    args << '--user' << @resource[:asadminuser]
    # Only add passwordfile if specified
    args << '--passwordfile' << @resource[:passwordfile] if @resource[:passwordfile] and
      not @resource[:passwordfile].empty?
    
    wait_for_server_args = args

    # Need to add the passed_args to args array.  
    passed_args.each { |arg| args << arg }
    
    # Transform args array into a exec args string.  
    exec_args = args.join " "


    command = "asadmin #{exec_args}"
    Puppet.debug("asadmin command = #{command}")
    
    # Compile the actual command as the specified user. 
    command = "su - #{@resource[:user]} -c \"#{command}\"" if @resource[:user] and
      not command.match(/create-service/)
    # Debug output of command if required. 
    Puppet.debug("exec command = #{command}")
    
    
    #wait_for_server(wait_for_server_args)
    # Execute the command. 
    output = `#{command}`
    # Check return code and fail if required
    self.fail output unless $? == 0
    
    # Split into array, for later processing...
    result = output.split(/\n/)
    Puppet.debug("result = \n#{result.inspect}")

    # Return the result
    result
  end

  def wait_for_server(args)

   if @@up_and_running == true
      return true
   end

   # Get timeout
   if @resource.parameters.include?(:timeout_seconds)
     seconds = @resource[:timeout_seconds]
     Puppet.debug("set #{seconds} seconds")
   else
     seconds = 120
   end

   # Transform args array into a exec args string.  
   exec_args = args.join " "
   command = "asadmin #{exec_args}"
   
   # Compile the actual command as the specified user. 
   command = "su - #{@resource[:user]} -c \"#{command} list-domains\"" if @resource[:user]
   # Debug output of command if required. 
   Puppet.debug("wait_for_server: exec command = #{command}")
 
   for i in 0..seconds
      # Execute the command. 
      output = `#{command}`
      # Check return code and fail if required
      self.fail output unless $? == 0
      
      # Split into array, for later processing...
      for line in output.split(/\n/)
         if line =~ /^[^\s]+\srunning$/
            Puppet.debug("Up an running")
            @@up_and_running = true
            return true
         end
      end
      Puppet.debug(sprintf("Waiting for server %i/%i seconds",i,seconds))
      sleep(1)
   end
   Puppet.debug("wait_for_server: failed - waited more than #{seconds}")
  end

  def escape(value)
    # Add three backslashes to escape the colon
    return value.gsub(/:/) { '\\:' }
  end
  
  # def exists?
  #     commands :asadmin => "#{@@asadmin}"
  #     version = asadmin('version')
  #     return false if version.length == 0
      
      # version.each do |line|
      #   if line =~ /(Version)/
      #     return true
      #   else 
      #     return false
      #   end
      # end
  # end
  
  protected
  
  def hasProperties?(props)
    unless props.nil?
      return (not props.to_s.empty?)
    end
    return false
  end
  
  def prepareProperties(properties)
    if properties.is_a? String
      return properties
    end
    if properties.is_a? Array
      return properties.join(':')
    end
    if not properties.is_a? Hash
      return properties.to_s
    end
    list = []
    properties.each do |key, value|
      rkey = key.to_s.gsub(/([=:])/, '\\\\\\1')
      rvalue = value.to_s.gsub(/([=:])/, '\\\\\\1')
      list << "#{rkey}=\\\"#{rvalue}\\\""
    end
    return list.sort!.join(':')
  end   
    
end
