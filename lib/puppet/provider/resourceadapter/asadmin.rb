require 'puppet/provider/asadmin'

Puppet::Type.type(:resourceadapter).provide(:asadmin, :parent =>
Puppet::Provider::Asadmin) do
  desc "Glassfish resourceadapter deployment support."
  def create
    args = Array.new
    args << "deploy"
    args << "--type rar" 
    args << "--name" << @resource[:name]
    args << @resource[:source]

    asadmin_exec(args)
  end

  def destroy
    args = Array.new
    args << "undeploy"
    args << "--name" << @resource[:name]

    asadmin_exec(args)
  end

  # TODO: checken ob das reicht
  def exists?
    args = Array.new
    args << "list-applications"
    args << @resource[:target] if @resource[:target]

    asadmin_exec(args).each do |line|
      return true if @resource[:name] == line.split(" ")[0]
    end
    return false
  end
end
