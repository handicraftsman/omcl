module OMCL
  def self.launchMC(name, path)
    unless $authed
      RG::Log.crash "Did not authenticate!"
    end
    dat = YAML.load_file "#{path}/conf.yml"
    libs = Dir[path+"/libraries/**/*.*"]
    libs = libs.join ":"
    libs = libs + ":#{path}/bin/#{name}.jar"

    p dat

    min_mem = (dat["min_mem"] or "768M")
    max_mem = (dat["max_mem"] or "1G")
    main_class = (dat["mainclass"] or "net.minecraft.client.main.Main")

    opts = (dat["java_options"] or "")

    java_opts = <<-DATA
-server
-d32
-Xms#{min_mem}
-Xmx#{max_mem}
-Djava.library.path=#{path}/bin/natives/
-cp #{libs}
#{main_class}
#{opts}
DATA
    java_opts = java_opts.gsub(/\n/, " ")

    RG::Log.write "Starting..."

    cmd = "java #{java_opts} --username #{$username} --version #{name} --gameDir #{path} --assetsDir #{path}/assets --assetIndex #{dat["assets"].squish} --uuid #{$uid} --accessToken #{$access_token} --userType legacy --versionType #{dat["type"]} --nativeLauncherVersion 307"
    RG::Log.write "Launch command: " + cmd
    exec cmd
  end
end