require "rubygoods"

require "yaml"
require "http"

require "omcl/version"
require "omcl/auth"
require "omcl/dat"
require "omcl/launch"

class NilClass; def downcase; nil; end; end;

module OMCL
  def self.load_conf
    dirname = File.expand_path "~/omcl/"
    unless Dir.exists? dirname
      RG::Log.warn "No working directory detected! Creating #{dirname}..."
      Dir.mkdir dirname
    end

    cfgfilename = File.expand_path "~/omcl/conf.yml"
    unless File.exist? cfgfilename
      RG::Log.warn "No config file detected! Creating #{cfgfilename}..."
      File.open(cfgfilename, 'w') do |file| 
        file.write <<-YAML
# Basic auth-server entry
auth.serv.mojang: https://authserver.mojang.com/authenticate

# Sample mojang-account entry
account.mojang.handicraftsman:
  user: nickolay02@inbox.ru
  pass: <hidden>
YAML
      end
    end

    $conf     = YAML.load_file cfgfilename
    $auth     = {}
    $profiles = {}

    $conf.each do |name, content|
      if m = /^auth\.(.+)\.(.+)/.match(name)
        case m[1].squish
        when "serv"
          $type = :online
        when "token"
          $type = :offline
        end
        $auth[m[2]] = OMCL::AuthService.new $type, content
      elsif m = /account\.(.+)\.(.+)/.match(name)
        if $auth.include? m[1]
          auth = m[1]
          user = content["user"]
          pass = content["pass"]
          $profiles["#{m[1]}.#{m[2]}"] = OMCL::Account.new auth, user, pass
        else
          RG::Log.err "Unknown auth service: #{m[1]}"
        end
      end
    end 
  end
end