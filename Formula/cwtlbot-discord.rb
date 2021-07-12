class CwtlbotDiscord < Formula
  desc "Codewars Trainer Link Bot for Discord"
  homepage "https://github.com/DonaldKellett/cwtlbot-discord"
  url "https://github.com/DonaldKellett/cwtlbot-discord/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "5f3a1fca974f9d32a670185f1d9597551cd878bc6b3652f806e5d4eb1f296182"
  license "AGPLv3+"
  depends_on "node"

  def install
    (etc/"cwtlbot-discord"/"token").write "YOUR_BOT_TOKEN_HERE"
    (etc/"cwtlbot-discord"/"username").write "YOUR_BOT_USERNAME_HERE"
    (share/"cwtlbot-discord").install "index.js"
    (share/"cwtlbot-discord").install "package-lock.json"
    (share/"cwtlbot-discord").install "package.json"
    (bin/"cwtlbot-discord").write <<~EOS
      #!/bin/bash

      print_help() {
        echo "Usage:"
        echo "  cwtlbot-discord [--init | --version]"
      }

      if [[ $# -gt 1 ]]; then
        print_help
        exit 1
      fi

      if [[ $# -eq 0 ]]; then
        cd #{share/"cwtlbot-discord"}
        CONFIG_PATH=#{etc/"cwtlbot-discord"} npm start
        exit
      fi

      if [[ "$1" = --init ]]; then
        echo -n "Enter the login token for your Discord bot: "
        IFS= read -rs token
        echo "$token" > #{etc/"cwtlbot-discord"/"token"}
        echo ""
        echo -n "Enter the username for your Discord bot: "
        IFS= read -r username
        echo "$username" > #{etc/"cwtlbot-discord"/"username"}
        cd #{share/"cwtlbot-discord"}
        npm install
        exit
      fi

      if [[ "$1" = --version ]]; then
        echo "0.1.1"
        exit
      fi

      print_help
      exit 1
    EOS
    system "chmod", "555", bin/"cwtlbot-discord"
  end

  def caveats
    <<~EOS
      cwtlbot-discord should be initialized with the login token and username of your Discord bot before using it. Do this by running the following command:
      $ cwtlbot-discord --init
    EOS
  end
end
