class Jenkins < Formula
  desc "Extendable open source continuous integration server"
  homepage "https://jenkins.io/"
  url "http://mirrors.jenkins.io/war/2.249/jenkins.war"
  sha256 "229bd71c7b96d1ae0290a3465dee21eac20b7fe494598e807fcef60a9e7c9638"
  license "MIT"

  head do
    url "https://github.com/jenkinsci/jenkins.git"
    depends_on "maven" => :build
  end

  bottle :unneeded

  depends_on "openjdk@11"

  def install
    if build.head?
      system "mvn", "clean", "install", "-pl", "war", "-am", "-DskipTests"
    else
      system "#{Formula["openjdk@11"].opt_bin}/jar", "xvf", "jenkins.war"
    end
    libexec.install Dir["**/jenkins.war", "**/jenkins-cli.jar"]
    bin.write_jar_script libexec/"jenkins.war", "jenkins", :java_version => "11"
    bin.write_jar_script libexec/"jenkins-cli.jar", "jenkins-cli", :java_version => "11"
  end

  def caveats
    <<~EOS
      Note: When using launchctl the port will be 8080.
    EOS
  end

  plist_options :manual => "jenkins"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{Formula["openjdk@11"].opt_bin}/java</string>
            <string>-Dmail.smtp.starttls.enable=true</string>
            <string>-jar</string>
            <string>#{opt_libexec}/jenkins.war</string>
            <string>--httpListenAddress=127.0.0.1</string>
            <string>--httpPort=8080</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    EOS
  end

  test do
    ENV["JENKINS_HOME"] = testpath
    ENV.prepend "_JAVA_OPTIONS", "-Djava.io.tmpdir=#{testpath}"

    port = free_port
    fork do
      exec "#{bin}/jenkins --httpPort=#{port}"
    end
    sleep 60

    output = shell_output("curl localhost:#{port}/")
    assert_match /Welcome to Jenkins!|Unlock Jenkins|Authentication required/, output
  end
end
