class DonaldsebleungCom < Formula
  desc "My personal website reinstated, this time written in Spring"
  homepage "https://github.com/DonaldKellett/donaldsebleung-com"
  url "https://github.com/DonaldKellett/donaldsebleung-com/archive/refs/tags/v0.2.3.tar.gz"
  sha256 "9cda642d97c49ce9cec2d3f9bf54e97fd5f8cbb6a8a398cbc301281e10e083a8"
  license "MIT"
  depends_on "maven" => :build
  depends_on "openjdk"
  depends_on "openssl"

  def install
    system "mvn", "package"
    (share/"donaldsebleung-com").install "target/personal-website-0.0.1-SNAPSHOT.jar"
    (etc/"donaldsebleung-com"/"passwd").write "P@ssw0rd"
    (etc/"donaldsebleung-com"/"keyalias").write "keyalias"
    (bin/"donaldsebleung-com").write <<~EOS
      #!/bin/bash
      
      print_usage() {
        echo "Usage: donaldsebleung-com <command> [args...]"
        echo "  where command can be one of:"
        echo "    get-version"
        echo "    install-key"
        echo "    install-cert"
        echo "    set-passwd"
        echo "    set-keyalias"
        echo "    start-service"
        echo ""
        echo "Examples:"
        echo "  Getting the version:"
        echo "  $ donaldsebleung-com get-version"
        echo "  Installing key-certificate pair:"
        echo "  $ donaldsebleung-com install-key < /path/to/your/key.pem"
        echo "  $ donaldsebleung-com install-cert < /path/to/your/cert.pem"
        echo "  Setting the key passphrase to MyP@ssw0rd:"
        echo "  $ donaldsebleung-com set-passwd \"MyP@ssw0rd\""
        echo "  Setting the key alias to myalias:"
        echo "  $ donaldsebleung-com set-keyalias \"myalias\""
        echo "  Starting the HTTPS server (binds to TCP port 443):"
        echo "  $ donaldsebleung-com start-service"
      }
      
      miss_keycert() {
        echo "Missing key-certificate pair!"
        echo "Ensure you have installed your CA-issued or self-signed key-certificate pair by running the following commands:"
        echo "$ donaldsebleung-com install-key < /path/to/your/key.pem"
        echo "$ donaldsebleung-com install-cert < /path/to/your/cert.pem"
        echo "If your key is protected by a passphrase, remember to set the password as well:"
        echo "$ donaldsebleung-com set-passwd <passphrase>"
      }
      
      if [[ $# -lt 1 || $# -gt 2 ]]; then
        print_usage
        exit 1
      fi
      
      if [[ $# -eq 2 ]]; then
        case $1 in
          set-passwd)
            echo "$2" > #{etc/"donaldsebleung-com"/"passwd"}
            chmod 600 #{etc/"donaldsebleung-com"/"passwd"}
            exit
            ;;
          set-keyalias)
            echo "$2" > #{etc/"donaldsebleung-com"/"keyalias"}
            exit
            ;;
          *)
            print_usage
            exit 1
            ;;
        esac
      fi
      
      case $1 in
        get-version)
          echo "0.2.3"
          exit
          ;;
        install-key)
          rm -f #{etc/"donaldsebleung-com"/"key.pem"}
          while IFS= read -r line; do
            echo "$line" >> #{etc/"donaldsebleung-com"/"key.pem"}
          done
          exit
          ;;
        install-cert)
          rm -f #{etc/"donaldsebleung-com"/"cert.pem"}
          while IFS= read -r line; do
            echo "$line" >> #{etc/"donaldsebleung-com"/"cert.pem"}
          done
          exit
          ;;
        start-service)
          if [[ "$(whoami)" != root ]]; then
            echo "Command start-service must be run as root"
            exit 1
          fi
          test -f #{etc/"donaldsebleung-com"/"key.pem"}
          if [[ $? -ne 0 ]]; then
            miss_keycert
            exit 1
          fi
          test -f #{etc/"donaldsebleung-com"/"cert.pem"}
          if [[ $? -ne 0 ]]; then
            miss_keycert
            exit 1
          fi
          test -f #{etc/"donaldsebleung-com"/"passwd"}
          if [[ $? -ne 0 ]]; then
            echo "Missing password file, please run the following command to set the password to <passphrase>:"
            echo "$ donaldsebleung-com set-passwd <passphrase>"
            exit 1
          fi
          test -f #{etc/"donaldsebleung-com"/"keyalias"}
          if [[ $? -ne 0 ]]; then
            echo "Missing keyalias file, please run the following command to set the keyalias to <keyalias>:"
            echo "$ donaldsebleung-com set-keyalias <keyalias>"
            exit 1
          fi
          TMP_DIR="$(mktemp -d)"
          cat #{etc/"donaldsebleung-com"/"key.pem"} #{etc/"donaldsebleung-com"/"cert.pem"} > "$TMP_DIR/keycert.pem"
          openssl pkcs12 -export -in "$TMP_DIR/keycert.pem" -out "$TMP_DIR/keystore.pkcs12" -name "$(cat #{etc/"donaldsebleung-com"/"keyalias"})" -noiter -nomaciter -passin pass:"$(cat #{etc/"donaldsebleung-com"/"passwd"})" -passout pass:"$(cat #{etc/"donaldsebleung-com"/"passwd"})"
          SPRING_PROFILES_ACTIVE=prod SERVER_SSL_KEY_STORE=file://"$TMP_DIR/keystore.pkcs12" SERVER_SSL_KEY_STORE_PASSWORD="$(cat #{etc/"donaldsebleung-com"/"passwd"})" SERVER_SSL_KEY_ALIAS="$(cat #{etc/"donaldsebleung-com"/"keyalias"})" java -jar #{share/"donaldsebleung-com"/"personal-website-0.0.1-SNAPSHOT.jar"}
          exit
          ;;
        *)
          print_usage
          exit 1
          ;;
      esac
    EOS
    system "chmod", "555", bin/"donaldsebleung-com"
  end

  def caveats
    <<~EOS
      The start-service command has to be run as root to bind to TCP port 443 for starting the HTTPS server. However, binaries installed by Homebrew are not in root's PATH by default. Fix this by creating the appropriate symlinks for the following binaries: donaldsebleung-com, java, openssl

      $ sudo ln -s "$(which donaldsebleung-com)" /usr/local/bin/donaldsebleung-com
      $ sudo ln -s "$(which java)" /usr/local/bin/java
      $ sudo ln -s "$(which openssl)" /usr/local/bin/openssl
    EOS
  end
end
