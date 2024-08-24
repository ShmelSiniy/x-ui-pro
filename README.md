## x-ui-pro (x-ui + warp + nginx) :octocat:	:open_file_folder:	
- Auto Installation (lightweight)
- Auto SSL renewal / Daily reload Nginx X-ui
- Handle **WebSocket/GRPC/HttpUgrade/SplitHttp** via **nginx**.
- Multi-user and config via port **443**
- Install multiple domains with one server/panel
- More security and low detection with nginx
- Compatible with Cloudflare
- Random 150+ fake template!
- Install only in Linux Debian/Ubuntu!
  
➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖

**Install X-UI-PRO**:dvd::package:

```
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/x-ui-pro.sh) -install yes -panel 0 -ONLY_CF_IP_ALLOW no"
```
> 
> Recommended -ONLY_CF_IP_ALLOW yes + (Cloudflare<img src="https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/cdnon.png" width="34">TURN ON) + SSL/TLS > Full
>
> Cloudflare > yourDomain > Network > gRPC <img src="https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/TURNON.png" width="28">
> ##
> SSL Support (yourdomain.com, *.yourdomain.com) for new subdomain, just add a new record A,AAAA[IP] in domain dns management! no need to reinstall the
panel!
> 
> -panel (0=alireza 1=MHSanaei 2=FranzKafkaYu)
> 
**Random Fake HTMLSite**:earth_asia:	
```
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/randomfakehtml.sh)"
```

**Uninstall X-UI-PRO**:x:
```
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/x-ui-pro.sh) -uninstall yes"
```

➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
### Server Configuration :wrench:🐧⚙️
![](https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/Config_XUI_ADMIN_4.jpg)
![](https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/grpc_config_format.jpg)
➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
### Client Configuration :white_check_mark:	:computer:🔌
![](https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/XUI_CONFIG_XRAY_CLIENT_EDIT2.png)
➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
### Enable WARP<img src="https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/cdnon.png" width="34"> (Fix Error 403-Forbidden Google Search)
![](https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/error403Google.png)
#### XUI PANEL> Xray Configs> Outbands > Add WARP > Create > Add > Save Restart!
![](https://raw.githubusercontent.com/GFW4Fun/x-ui-pro/master/media/Enable_WARP.jpg)
#### XUI PANEL> Xray Configs> Routing Rules> Add Rules > 
#### Inbound Tags (Select Your Configs/inbounds) + Outbound Tag (WARP outbound) > Add rule! > Save Restart!
➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
### Cloudflare Find Good IP (VPN off❗ during scanning)
Cloudflare IP Ranges: https://www.cloudflare.com/ips/

Cloudflare IP Scanner: [vfarid](https://vfarid.github.io/cf-ip-scanner/) | [goldsrc](https://cloudflare-scanner.vercel.app) | [ircfspace](https://ircfspace.github.io/scanner/)

➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
### Enable UFW :no_entry_sign: Firewall (Prevent direct access to x-ui-xray ports)
```
apt update && apt install ufw
ufw reset && ufw allow ssh && ufw allow ftp && ufw allow http && ufw allow https
ufw enable && ufw reload && ufw status
```
➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
##
[![Star History Chart](https://api.star-history.com/svg?repos=GFW4Fun/x-ui-pro&type=Date)](https://github.com/GFW4Fun/x-ui-pro)

