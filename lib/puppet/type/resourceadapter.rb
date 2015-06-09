Puppet::Type.newtype(:resourceadapter) do
  @doc = "Manage resourceadapters of Glassfish domains"
  ensurable

  newparam(:name) do
    desc "The resourceadapter name."
    isnamevar

    validate do |value|
      unless value =~ /^[\w\-\.]+$/
         raise ArgumentError, "%s is not a valid resourceadapter name." % value
      end
    end
  end

  newparam(:source) do
    desc "The application file to deploy."
  end

  newparam(:portbase) do
    desc "The Glassfish domain port base. Default: 4800"
    defaultto '4800'   

    validate do |value|
      raise ArgumentError, "%s is not a valid portbase." % value unless value =~ /^\d{4,5}$/
    end

    munge do |value|
      case value
      when String
        if value =~ /^[-0-9]+$/
          value = Integer(value)
        end
      end

      return value
    end
  end

  newparam(:asadminuser) do
    desc "The internal Glassfish user asadmin uses. Default: admin"
    defaultto "admin"

    validate do |value|
      unless value =~ /^[\w-]+$/
         raise ArgumentError, "%s is not a valid asadmin user name." % value
      end
    end
  end

  newparam(:passwordfile) do
    desc "The file containing the password for the user."

    validate do |value|
      unless File.exists? value
        raise ArgumentError, "%s does not exists" % value
      end
    end
  end

  newparam(:user) do
    desc "The user to run the command as."

    validate do |value|
      unless Puppet.features.root?
        self.fail "Only root can execute commands as other users"
      end
      unless value =~ /^[\w-]+$/
         raise ArgumentError, "%s is not a valid user name." % value
      end
    end
  end
  
  # Validate mandatory params
  validate do
    raise Puppet::Error, 'Source is required.' if self[:source].nil? and self[:ensure] == :present
  end
  
  # Autorequire the user running command
  autorequire(:user) do
    self[:user]    
  end
  
  # Autorequire the source resourceadapter file
  autorequire(:file) do 
    self[:source]
  end
end