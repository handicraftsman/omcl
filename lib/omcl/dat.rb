module OMCL
  class Account
    attr_accessor :auth, :user, :nick, :pass, :token

    def initialize(auth, user, pass=nil)
      @auth = auth
      @user = user
      @pass = pass
    end
  end

  class AuthService
    attr_accessor :type, :url, :token

    def initialize(type, input)
      if type == :online
        @type  = :online
        @url   = input
      else
        @type  = :offline
        @token = input
      end
    end
  end
end