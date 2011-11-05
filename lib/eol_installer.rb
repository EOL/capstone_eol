module EOLInstallation

  class RVMInstaller
    # TODO
  end

  class GemInstaller    
    
    def initialize(dry_run=true)
      @dry_run = dry_run
    end

    def install_gems(gems)    
      gems.each do |gem|
        sh "gem install #{gem}"
      end   
    end

    def run_bundler()  
      puts "running bundler"
      if not @dry_run    
        sh "bundle install"
      end
    end

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
  
    #set up databse base
    def db_setup
      puts "setting up the database..."
      #based on README.rdoc
      if not File.exists?("config/database.yml")
        FileUtils.copy("config/database.sample.yml", "config/database.yml")        
      end           

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

    def db_setup()
      super.db_setup()

      #keep in sub class until we get this working without using shell
      if not @dry_run
        #call rake task required to build the db / set up scenario / solr 
        Rake::Task["db:create:all"].invoke()
        Rake::Task["db:migrate"].invoke() 
        sh "rake db:migrate RAILS_ENV=test" #figure out how to pass params properly
        sh "rake db:migrate RAILS_ENV=test_master"
        Rake::Task["solr:start"].invoke()
        Rake::Task["truncate"].invoke() 
        sh "rake scenarios:load NAME=bootstrap,demo"
        sh "rake solr:build RAILS_ENV=test"
        Rake::Task["solr:rebuild_site_search"].invoke() 
        Rake::Task["solr:rebuild_collection_items"].invoke()  
           
      #attempt at using proper params but doesnt work
      #db_args = Rake::TaskArguments::new(["NAME"], ["bootstrap,demo"])
      #puts db_args.to_hash()
      #Rake::Task["scenarios:load"].invoke(db_args.to_hash())
      end 
     
    end

    def do_sysupdate
      if not @dry_run
        sh "sudo apt-get update"
        sh "sudo apt-get dist-upgrade"
      else
        puts "No sysupdate in dry run."     
      end
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
    os_type = RUBY_PLATFORM  

    if os_type.include? "linux" or os_type.include? "cygwin"
      uname = explicit || %x[uname -a]
      if uname.include? "Ubuntu"
        puts "Detected OS: Ubuntu"
        return UbuntuInstaller.new()
      end
    elsif os_type.include? "mac" or os_type.include? "darwin"
      puts "Mac OS detected"
    elsif os_type.include? "bsd"
      puts "BSD OS detected"
    elsif os_type.include? "mswin" or os_type.include? "win" or os_type.include? "mingw"
      puts "nice OS choice!!"
    elsif os_type.include? "solaris" or os_type.include? "sunos"
      puts "Solaris OS detected"
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
