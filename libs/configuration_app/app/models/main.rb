class Main < ActiveRecord::Base

	def self.scan_wifi_networks
    ap_list = %x{sudo iwlist scan}.split('Cell')
    ap_array = Array.new

    ap_list.each{|ap_grouping|
      ssid = ''

      ap_grouping.split("\n").each{|line|
        if line.include?('ESSID')
            ssid = line[27..-2]
        end
      }

      unless ssid == ''
        ap_array << ssid
      end
    }

    ap_array
	end

  def self.create_wpa_supplicant(ssid, wifi_key)
		temp_conf_file = File.new('../tmp/wpa_supplicant.conf.tmp', 'w')

		temp_conf_file.puts 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev'
		temp_conf_file.puts 'update_config=1'
		temp_conf_file.puts
		temp_conf_file.puts 'network={'
		temp_conf_file.puts '	ssid="' + ssid + '"'

		if wifi_key == 'open'
			temp_conf_file.puts '	key_mgmt=NONE'
		else
			temp_conf_file.puts '	psk="' + wifi_key + '"'
		end

		temp_conf_file.puts '}'

		temp_conf_file.close

		system('sudo cp ../tmp/wpa_supplicant.conf.tmp /etc/wpa_supplicant/wpa_supplicant.conf')
		system('rm ../tmp/wpa_supplicant.conf.tmp')
	end

  def self.set_ap_client_mode
    system ('sudo rm /etc/cron.raspiwifi/aphost_bootstrapper')
    system ('sudo cp /usr/lib/raspiwifi/reset_device/static_files/apclient_bootstrapper /etc/cron.raspiwifi/')
		system ('sudo chmod +x /etc/cron.raspiwifi/apclient_bootstrapper')
    system ('sudo mv /etc/dnsmasq.conf.original /etc/dnsmasq.conf')
    system ('sudo mv /etc/dhcpcd.conf.original /etc/dhcpcd.conf')

		system('sudo systemctl restart dnsmasq')
		system('sudo pkill -f "hostapd -dd /etc/hostapd/hostapd.conf"')
		system('sudo pkill -f "/usr/lib/raspiwifi/reset_device/reset.py"')
		system('sudo systemctl daemon-reload')
		system('sudo systemctl restart dhcpcd')
		system('sudo /etc/cron.raspiwifi/apclient_bootstrapper')
  end

end
