module OMCL
  def self.downloadMC(instance, version)
    instance = instance.downcase
    version  = version.downcase
    inst_path = "~/omcl/#{instance}"
    if version == nil
      RG::Log.crash "Version name is not set!"
    end
    if instance == nil
      RG::Log.crash "Instance name is not set!"
    end
    RG::Log.write "Loading JSON data..."
    unless $versions.include? version
      RG::Log.err "Invalid version!"
    end
    $ver_data_raw = HTTP.get $versions[version]
    $ver_data = JSON.load $ver_data_raw.body.to_s
    RG::Log.write "Installing minecraft..."
    if Dir.exist? File.expand_path "#{inst_path}"
      print "Instance #{instance} already exists. Rewrite? [y/N] "
      answer = STDIN.gets[0].downcase
      if answer == "y"
        FileUtils.remove_dir File.expand_path "#{inst_path}"
      else
        exit
      end
    end
    Dir.mkdir File.expand_path "#{inst_path}"
    Dir.mkdir File.expand_path "#{inst_path}/bin"
    Dir.mkdir File.expand_path "#{inst_path}/bin/natives"
    Dir.mkdir File.expand_path "#{inst_path}/assets"
    Dir.mkdir File.expand_path "#{inst_path}/assets/indexes"
    Dir.mkdir File.expand_path "#{inst_path}/assets/objects"
    Dir.mkdir File.expand_path "#{inst_path}/libraries"
    jar_data = HTTP.get $ver_data["downloads"]["client"]["url"]
    File.open(File.expand_path("#{inst_path}/bin/#{version}.json"), 'w') do |file| 
      file.write $ver_data_raw
    end
    File.open(File.expand_path("#{inst_path}/bin/#{version}.jar"), 'w') do |file| 
      file.write jar_data
    end
    RG::Log.write "Finished downloading minecraft.jar"

    thrs = []
    $ver_data["libraries"].each do |lib|
      thrs << Thread.new do
        unless lib.include? "extract"
          dat = HTTP.get(lib["downloads"]["artifact"]["url"]).body.to_s
          path = File.expand_path("#{inst_path}/libraries/" +
            lib["downloads"]["artifact"]["path"])
          FileUtils.mkpath File.dirname path 
          File.open(path, 'w') do |file|
            file.write dat
          end
          RG::Log.write "Finished downloading #{path}"
        else
          if lib["downloads"]["classifiers"]["natives-linux"]
            url = lib["downloads"]["classifiers"]["natives-linux"]["url"]
            path = File.expand_path("#{inst_path}/bin/natives/" +
              (File.basename lib["downloads"]["classifiers"]["natives-linux"]["path"]))
            dat = HTTP.get(url).body.to_s
            File.open(path, 'w') do |file|
              file.write dat
            end
            RG::Log.write "Finished downloading native #{path}"
          end
        end
      end
      sleep 0.01
    end
    thrs.each do |t| t.join end

    ["", "_util"].each do |a|
      pth = File.expand_path "~/omcl/#{version}/libraries/org/lwjgl/lwjgl/lwjgl#{a}/*"
      x = Dir[pth]
      x = x.map do |o| /.*\/(\d\.\d\.\d).*/.match(o)[1] end
      x = x.map do |o| Gem::Version.new o end
      $m = x.max.to_s
      x = Dir[pth]
      x.each do |o|
        unless o[/#{File.dirname pth}\/#{$m.gsub(/\./, "\\.")}.*/]
          FileUtils.remove_dir o
        end
      end
    end

    RG::Log.write "Finished 'patching' lwjgl"

    lwjgled = false
    Dir[File.expand_path "#{File.expand_path "#{inst_path}/bin/natives"}/*.jar"].each do |f|
      if ((f.include? $m[0,$m.length-2]) and (f.include? "lwjgl") and !lwjgled) or !(f.include? "lwjgl")
        if f.include? "lwjgl"
          lwjgled = true
        end
        `unzip -d #{File.expand_path "#{inst_path}/bin/natives"} #{f}`
        if File.exist? File.expand_path "#{inst_path}/bin/natives/META-INF"
          FileUtils.remove_dir File.expand_path "#{inst_path}/bin/natives/META-INF"
        end
        RG::Log.write "Finished unpacking native #{f}"
      end
    end
    RG::Log.write "Finished unpacking natives"

    aindex = HTTP.get $ver_data["assetIndex"]["url"]
    aindex_data = JSON.load aindex
    File.open(File.expand_path("~/omcl/#{version}/assets/indexes/#{$ver_data["assetIndex"]["id"]}.json"), 'w') do |file|
      file.write aindex
    end
    RG::Log.write "Finished downloading asset index"

    thrs = []
    if $ver_data["assetIndex"]["id"] == "legacy"
      aindex_data["objects"].each do |name, content|
        thrs << Thread.new do
          path = File.expand_path "~/omcl/#{version}/assets/objects/#{name}"
          FileUtils.mkdir_p File.dirname path
          dat = HTTP.get "http://resources.download.minecraft.net/#{content["hash"][0,2]}/#{content["hash"]}"
          File.open(path, 'w') do |file|
            file.write dat
          end
          RG::Log.write "Finished downloading asset #{path}"
        end
        sleep 0.01
      end
    else
      aindex_data["objects"].each do |_, content|
        thrs << Thread.new do
          path = File.expand_path "~/omcl/#{version}/assets/objects/#{content["hash"][0,2]}/#{content["hash"]}"
          FileUtils.mkdir_p File.dirname path
          dat = HTTP.get "http://resources.download.minecraft.net/#{content["hash"][0,2]}/#{content["hash"]}"
          File.open(path, 'w') do |file|
            file.write dat
          end
          RG::Log.write "Finished downloading asset #{path}"
        end
        sleep 0.01
      end
    end
    thrs.each do |t| t.join end
    RG::Log.write "Finished downloading assets!"

    File.open(File.expand_path("#{inst_path}/conf.yml"), 'w') do |file|
      dat = {
        "version" => version, 
        "mainclass" => $ver_data["mainClass"],
        "assets" => $ver_data["assets"],
        "type" => $ver_data["type"],
        "java_options" => ""
      }
      file.write YAML.dump dat
    end 
    RG::Log.write "Finished writing launcher config"
  end
end