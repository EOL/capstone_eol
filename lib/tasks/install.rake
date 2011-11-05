# These tasks can be used to prepare a fresh Ubuntu machine for EOL dev

require 'eol_installer'

PACKAGES = EOLInstallation::BASE_OS_PACKAGES
begin
  installer = EOLInstallation::get_installer()
  installer.dry_run = true
rescue UnknownOperatingSystemError => e
  abort "Cannot determine your operating system, aborting rake install!"
end

# ========================
# Helpers
# ========================

#prompts user for imput with the specified message
def input_prompt(message)
  puts "" + message 
  STDIN.gets.chomp
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



RVM_PACKAGES = {
  :openssl    => ["openssl"],
  :readline   => ["readline"],
  :iconv      => ["iconv"]
}

# ========================
# Rake tasks
# ========================

desc "Prepare a fresh Ubuntu machine for development"
task :install => ["install:sysupdate", "install:all", "install:rvm", "install:gems", "install:db_setup"]

namespace :install do

  desc "Bootstrap fresh box for installation"
  task :sysupdate do    
    installer.do_sysupdate 
  end

  PACKAGES.each do |package_name|
    desc "Install #{package_name}"
    task package_name do
      installer.send("install_#{package_name}")
    end
  end

  desc "install all system packages"
  task :all => PACKAGES

  desc "Install RVM"
  task :rvm => [:curl] do
    puts "trying install"
    sh "bash lib/tasks/rvm_installer"        
    sh ". ~/.bashrc"
    sh ". ~/.bash_profile"
  end

  desc "database configuraetion"
  task :db_setup do       
    installer.db_setup	
  end

  namespace :rvm do

    desc "Install all RVM packages"
    task :all => RVM_PACKAGES.keys

    RVM_PACKAGES.each do |package_name, libs|
      desc "Install RVM package #{package_name}"
      task package_name do
        rvm_install(libs)
      end
    end
    
  end

  desc "Install all gems"
  task :gems do
    puts "installing gems"
    gem_installer = EOLInstallation::GemInstaller.new(installer.dry_run)    
    
    gem_installer.install_gems(["bundler"])
    gem_installer.run_bundler()
  end

end
