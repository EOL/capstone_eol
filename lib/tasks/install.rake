# These tasks can be used to prepare a fresh Ubuntu machine for EOL dev

# ========================
# Helpers
# ========================

#prompts user for imput with the specified message
def input_prompt(message)
  puts "" + message 
  STDIN.gets.chomp
end

#sets up ssh if neccessaty and waits for user to link the ssh key to git hub
def ssh_setup()
  email = input_prompt("Please enter you github email")  
  sh "ssh-keygen -t rsa -c #{email}"
  puts "Add the following key you your github account"
  sh "cat .ssh/id_rsa.pub"
  #is below the correct git clone command???
  #maybe loop if cant clone
  #sh "git clone git@github.com:EncyclopediaOfLife/eol.git eol"
end

def is_installed?(package)
  sh "dpkg -l '#{package}' > /dev/null" do |ok, res|
    return ok
  end
end

def do_install(packages)
  packages.each do |package|
    sh "sudo apt-get install -y #{packages.join(' ')}" if !is_installed? package
    #puts "Rake will install #{package}" if !is_installed? package
  end
end

#gets all packages with sudo apt-get
def sudo_apt_get(packages)
  packages.each do |package|     
    sh "sudo apt-get #{package}"    
  end
end

#installs all packages with sudo apt-get install
def sudo_apt_get_install(packages)
  packages.each do |package|     
    sh "sudo apt-get install #{package}"    
  end
end

def rvm_install(*packages)
  sh "rvm install #{packages.join(' ')}"
end

PACKAGES = {
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

RVM_PACKAGES = {
  :openssl    => ["openssl"],
  :readline   => ["readline"],
  :iconv      => ["iconv"]
}

# ========================
# Rake tasks
# ========================

desc "Prepare a fresh Ubuntu machine for development"
task :install => ["install:sysupdate", "install:all", "install:rvm", "install:gems"]

namespace :install do

  desc "Bootstrap fresh box for installation"
  task :sysupdate do    
    sudo_apt_get(["update", "dist-upgrade"])
    sudo_apt_get_install(["build-essential"])
    #ssh_setup #uncomment if we decide to do an interactive install    
  end

  PACKAGES.each do |package_name, libs|
    desc "Install #{package_name}"
    task package_name do
      do_install(libs)
    end
  end

  desc "install all system packages"
  task :all => PACKAGES.keys 

  desc "Install RVM"
  task :rvm => [:curl] do
    sh "bash < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)"
    sh ". ~/.bashrc"
  end

  namespace :rvm do

    desc "Install all RVM packages"
    task :all => RVM_PACKAGES.keys

    RVM_PACKAGES.each do |package_name, libs|
      desc "Install RVM package #{package_name}"
      task package_name do
        do_install(libs)
      end
    end
    
  end

  desc "Install all gems"
  task :gems do
    sh "gem install bundler"
    sh "bundle install"
  end

end
