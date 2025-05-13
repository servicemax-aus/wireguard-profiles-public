# WireGuard MobileConfig Generator for macOS MDM

## Automatic, Always On Wireguard VPN

Unifi has a built in Wireguard VPN Server, and it's fantastic.  
What's not fantastic is that you must add a User by name, download the Wireguard config profile, then click 'Add' and then 'Save' for each person, or bunch of persons. Honestly that workflow was designed by satan to maximise the error rate.  
You can send those `.conf` files to users and they can get online without massive issues, but there's a lot that could be improved...  
  
This project processes the `.conf` files produced by Unifi from their Wireguard VPN Server, and generates `.mobileconfig` profiles for deploying WireGuard VPN configurations to macOS devices via MDM, such as **Mosyle**. 
Making them into a `.mobilecofig` and deploying via an MDM means they are less likely to be modified and easier to update with your tooling.

The supplied template is an automated 'always on' Wireguard config. We spent several months automating the creation of Wireguard configs with user control, but this seems the most ideal. If you want a template that requires user intervention let us know.

It is designed to:
- Automatically process `.conf` files
- Supports multiple Companies with a single env file for each company
- Insert required IPs and DNS values
- Output clean, MDM-compatible `.mobileconfig` files
- Names output files by Staff name and Company name
- Handles multiple files at once for multiple companies

When installled, this profile will automatically connect to the Wireguard VPN without user intervention. If the user goes into the Office, the Profile will detect the Office DNS Server and turn the VPN OFF.  

Read to the end if you want to host this in Github and run the script via Github Actions...  

## It's totally hands free, secure and FAST!


---

## ⚙️ Requirements

For running this shell script on a local Mac, you must have the following installed:

- `bash`
- `xmlstarlet` (for structured XML edits)
  ```bash
  brew install xmlstarlet

- `sed`, `awk`, `tr` (standard UNIX tools, pre-installed on macOS)
- A valid `template.xml` containing placeholders (**provided- must be edited before use**)


## 📁 Required Directory Structure
<pre>

.
├── configs/            # WireGuard config files (input)
│   └── First_Last_Company.conf
├── env/                # Lowercase .env files for each company
│   └── company.env
├── output/             # Final .mobileconfig files (output)
├── template.xml        # XML profile template with placeholders
├── generate.sh         # Main script

</pre>


## 🔧 Example env/company.env 
In your `company.env` file, set your IPs like this-  
**ALLOWED_IPS** are any IP addresses in the LAN or VLAN behind your Unifi router that are allowed for the client to access. Example- Server, Printer etc.  
You can add multiple Allowed IPs, separated by a comma. You should include **VPN Server Gateway IP**, **VPN Client IP**, **DNS Server IP** and the IP of any Services that hte client is allowed to connect on the other side of the VPN. The DNS Server appears on both lines because I was lazy, I'll fix it later. 
Why we don't use the traditional **AllowedIPs = 0.0.0.0/0** ?
Because our way sets up a split tunnel where only traffic supposed to go over the VPN goes over the VPN. This reduces traffic on your VPN Server.

**DNS_SERVER** this is the IP address of any DNS Server that will cause the Wireguard VPN to turn off.  
ie. When the computer connects to any network with a DHCP Server, and this IP is detected as the offered DNS from a DHCP Server, then wireguard VPN will be disabled by the `.mobileconfig` Profile.  
You can add multiple DNS Servers, separated by a comma.  

`cat company.env`  
`ALLOWED_IPS="192.168.200.11/32"`  
`DNS_SERVER="192.168.210.1"`


Name this file after the company (lowercase), matching the suffix of the .conf file.
Example:
You created a `.conf` file for 'John Doe' from Pepsi, the file would be- `configs/Johnn_Doe_Pepsi.conf`, the corresponding .env file should be named:

`env/pepsi.env`  
The Company name should have no spaces and capitalisation does not matter as the script sweeps through twice.  

## 🚀 How to Operate

1. Download the code or clone the repo, open the `template.xml` file and add your own UUIDs.
   You can make these on macOS by opening Terminal and executing  

`uuidgen`  

2. Create your 	`env` files for each Company name. These contain the allowed IPs and set the DNS Server that we detect as being in the 'Office'. We set the allowed IP as the Server, so the client can't connect to anything else in the Office while on VPN, (you can add more IPs separated by commas).
3. Download the .conf files you need from your Unifi Portal, name them like this- 'FirstName_LastName_Company.conf'
   Then upload them to the 'conf' folder in this project

5. Make the script executable:

` chmod +x generate.sh`

 2. Run the script:

 ` ./generate.sh`

## ⚙️ What the Script Does in Detail
  For each `.conf` file in `configs/`:  
	•	Extracts the company name from the filename  
	•	Loads company-specific values from `env/company.env`  
	•	Replaces the AllowedIPs line in the config with the one from .env  
	•	Escapes special characters for XML   
	•	Inserts the WireGuard config, DNS, and Endpoint into the `template.xml`  
	•	Updates `PayloadIdentifier` values using the company name:  
	•	`com.company.vpn.profile`  
	•	`com.company.vpn.payload`  
	•	Outputs a final `.mobileconfig` file into `output/`  
	•	Deletes the intermediate `.processed.conf`  

 ## 🧩 Bonus! Use Github Workflows
Clone this repo, update your `template.xml` and `company.env` files, then use the workflow under `Actions` and trigger with a commit-   
`git add configs/John_Doe_Metropolis.conf`    
`git commit -m "Add new WireGuard config"`   
`git push`   

or do it manually-  

## ✅ Option 2: Manual Run (if the file is already committed)
1.	Go to the Actions tab on GitHub  
2.	Select `Generate WireGuard Profiles`   
3.	Click `Run workflow`  
4.	It will build using whatever `.conf` files are already in the repo  

 ## 📥 Downloading Output
1.	Once the workflow finishes, go to the latest run under `Actions`  
2.	Scroll down to the `Artifacts` section  
3.	Click on `wireguard-profiles` to download all `.mobileconfig` files  
4.	These can then be uploaded to Mosyle (or your MDM) and pushed to clients   
 
## 💡 Optional Tip- Run from Readme
[▶️ Run Profile Generator](../../actions/workflows/build-wireguard.yml)  
This provides a 1-click link to manually run the workflow- click 'run' on the next page...  

## Mega Dream Express Pro SE Ultra Enterprise Max Bonus
For extra points from your users you can do this too  
- Set the Servername in `/etc/hosts` on client machines so users only have to remember `Company.Server` to connect  
- Add a link in Mosyle's 'Self-Service.app' so users can connect with a single click  
- If the Server is a Synology NAS you can set them up with Synology Drive so they don't need to remember anything   
- Because the VPN connection is 'automagic', the Synology Drive connection just works anywhere
- Make sure you've cosidered all the security implications because going home early might not be worth it if you suddenly get unlimited holidays and zero pay...  

## 👷 Author / Maintainer
 Added GPL V3 License on 29.4.2025. This code and accompanying text is provided without any warranty whatsoever. If you can improve this project, please contribute your improvements back to the comunity. If you use or write about this project, please include attribution to 'Adam Connor- Servicemax' so I can tell my Mum I'm famous on the internet.
