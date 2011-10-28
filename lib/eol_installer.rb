module EOLInstallation

  class RVMInstaller
    # TODO
  end

  class GemInstaller
    # TODO
  end

  # all OS installer must support the base EOL dependencies
  BASE_OS_PACKAGES = [:git, :curl, :zlib, :mysql, :memcached, :libxml2, :ssh]
  EXTRA_PACKAGES = [:dselect, :readline]

  # Base class for installing OS-specific packages
  class BaseSystemInstaller

    BASE_OS_PACKAGES.each do |base_pkg|
      eval(
      "def install_#{base_pkg}
        raise NotImplementedError.new('Implement me in a subclass!')
      end"
      )
    end

    # Install all base packages
    def install_all
      BASE_OS_PACKAGES.each {|pkg| self.send("install_#{pkg}")}
    end

    def do_sysupdate
      raise NotImplementedError.new('Implement me in a subclass!')
    end
  end

  # Installer for Ubuntu and perhaps Debian based systems
  class UbuntuInstaller < BaseSystemInstaller
    # now implement install_git(), install_curl(), etc.

    attr_accessor :packages, :dry_run
    # This is how Ubuntu understands what each package means
    @packages = {
      :git        => ["git-core"],
      :curl       => ["curl"],
      :dselect    => ["dselect"],
      :zlib       => ["zlib1g-dev"],
      :readline   => ["ncurses-dev", "libncurses5-dev", "libreadline-dev", "libreadline6", "libreadline6-dev"],
      :mysql      => ["mysql-server", "mysql-client", "libmysqlclient-dev"],
      :memcached  => ["memcached"],
      :libxml2    => ["libxml2-dev", "libxml2", "libxslt-dev"],
      :ssh        => ["openssh-server", "openssh-client"],
    }

    def initialize(dry_run=false)
      @manager = "apt-get"
      @dry_run = dry_run # simulation mode by default
    end

    @packages.each do |package_name, libs|
      eval(
        "def install_#{package_name}
          do_install(#{libs.inspect})
        end"
      )
    end

    def install_all()
      super.install_all()
      # extend this method if there's Ubuntu specific package that needs to be installed
    end

    def do_sysupdate

    end

    private

    # helper method to determine whether a package is installed or not
    def is_installed?(package)
      sh "dpkg -l '#{package}' > /dev/null" do |ok, res|
        return ok
      end
    end

    # helper methods to install packages
    def do_install(packages)
      packages.each do |package|
        sh "sudo #{@manager} install -y #{packages.join(' ')} #{'--dry-run' if @dry_run}" if !is_installed? package
      end
    end
    
  end

  class OSXInstaller < BaseSystemInstaller

  end


  # Main Factory Pattern (static method)
  def self.get_installer(explicit=nil)
    # either user specifies explicit OS or we try to guess
    uname = explicit || %x[uname -a] 

    if uname.include? "Ubuntu"
      puts "Detected OS: Ubuntu"
      return UbuntuInstaller.new()
    else
      raise UnknownOperatingSystemError.new("Cannot determine your Operating System, sorry!")
    end

  end

end

if __FILE__ == $PROGRAM_NAME
  installer = EOLInstallation::get_installer()
  installer.dry_run = true # just want to dry run for testing
  puts installer.install_all
end