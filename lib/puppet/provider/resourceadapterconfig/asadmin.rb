require 'puppet/provider/asadmin'

Puppet::Type.type(:resourceadapterconfig).provide(:asadmin, :parent =>
Puppet::Provider::Asadmin) do
  desc "Glassfish resource-adapter-config support."
  def create
    args = Array.new
    args << "create-resource-adapter-config"
    args << "--target" << @resource[:target] if @resource[:target]
    args << "'" + @resource[:name] + "=" + escape(@resource[:value]) + "'"

    asadmin_exec(args)
  end

  def destroy
    args = Array.new
    args << "delete-system-property"
    args << "--target" << @resource[:target]
    args << "'" + escape(@resource[:name]) + "'"

    asadmin_exec(args)
  end

  def exists?
    args = Array.new
    args << "list-system-properties"
    args << @resource[:target] if @resource[:target]

    asadmin_exec(args).each do |line|
      if line.match(/^[^=]+=/)
        key, value = line.split("=")
        return true if @resource[:name] == key
      end
    end
    return false
  end
end
