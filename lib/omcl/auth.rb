module OMCL
  module Auth
    def self.make_json_request(user, pass)
      RG::Log.write "Forming JSON request..."
      # Create hash
      dat = {
        :agent => {
          :name    => "Minecraft",
          :version => 1
        },
        :username => user,
        :password => pass
      }

      # Generate JSON request and return it
      JSON.generate dat
    end

    def self.authenticate(url, user, pass)
      # Create JSON request
      json = self.make_json_request user, pass
      RG::Log.write "Authenticating..."
      res = HTTP.headers(:accept => "application/json")
        .post(url, {:body=>json})
      if res.code == 403
        RG::Log.crash "Invalid credentials error! If they are valid, try again after a while"
      elsif res.code != 200
        RG::Log.crash "Received HTTP code #{res.code} while authenticating!"
      else
        return res
      end
    end
  end
end