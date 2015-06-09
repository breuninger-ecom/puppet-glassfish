require 'puppet/provider/asadmin'

Puppet::Type.type(:resourceadapter).provide(:asadmin, :parent =>
Puppet::Provider::Asadmin) do
  desc "Glassfish resourceadapter deployment support."
  def create

    if @resource[:source] =~ /http(s)?:\/\//
      # make this random later and purge file after deployment
      filename = "/tmp/glassfish-install-rar-with-puppet.rar"
      if not system("wget -O #{tmpfile} #{@resource[:source]}")
         raise RuntimeError, "unable to download #{@resource[:source]}"
      end
    else
      filename = @resource[:source]
    end

    args = Array.new
    args << "deploy --type rar" 
    args << "--name" << @resource[:name]
    args << filename
    asadmin_exec(args)
  end

  def destroy
    args = Array.new
    args << "undeploy"
    args << @resource[:name]

    asadmin_exec(args)
  end

  def exists?
    args = Array.new
    args << "list-applications"

    asadmin_exec(args).each do |line|
      if line =~ /^#{@resource[:name]}\s+<connector>/
         return true
      end
    end
    return false
  end
end
