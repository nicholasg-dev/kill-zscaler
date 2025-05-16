# Kill Zscaler for macOS

A simple utility to control Zscaler VPN service on macOS. This tool provides easy ways to stop and start Zscaler when needed.

## Features

- Simple GUI application to stop/start Zscaler
- Shell scripts for command-line control
- VPN tunnel sharing capability
- Support for shell aliases

## Using the App

The easiest way to use this tool is through the GUI applications:

1. Download and extract this repository
2. Use `Kill Zscaler.app` to stop Zscaler
3. Use `Start Zscaler.app` to restart Zscaler

![Kill Zscaler and Start Zscaler app](apps.png)

## Command Line Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/nicholasg-dev/kill-zscaler.git
   cd kill-zscaler
   ```

2. Make the scripts executable:
   ```bash
   chmod +x kill-zscaler.sh start-zscaler.sh
   ```

3. Run the scripts:
   ```bash
   ./kill-zscaler.sh  # To stop Zscaler
   ./start-zscaler.sh # To start Zscaler
   ```

## Shell Aliases

For quick access, you can set up shell aliases:

1. Open your shell's configuration file:
   - For Bash: `~/.bashrc`
   - For ZSH: `~/.zshrc`

2. Add these aliases:
   ```bash
   # Start Zscaler
   alias start-zscaler="open -a /Applications/Zscaler/Zscaler.app --hide; sudo find /Library/LaunchDaemons -name '*zscaler*' -exec launchctl load {} \;"
   
   # Stop Zscaler
   alias kill-zscaler="find /Library/LaunchAgents -name '*zscaler*' -exec launchctl unload {} \;;sudo find /Library/LaunchDaemons -name '*zscaler*' -exec launchctl unload {} \;"
   ```

3. Reload your shell configuration:
   ```bash
   source ~/.bashrc  # For Bash
   source ~/.zshrc   # For ZSH
   ```
## VPN Tunnel Sharing

You can share your Zscaler VPN tunnel with other devices using the `share-zscaler.v2.sh` script:

```bash
./share-zscaler.v2.sh --probe foo.bar.internal --domain internal
```

This will:
1. Set up NAT (Network Address Translation) on your VPN client
2. Configure DNS resolution for specified domains
3. Generate configuration instructions for other devices

Parameters:
- `--probe`: Hostname to test VPN connectivity
- `--domain`: Domain(s) to route through the VPN
      Display.Height=1080
      Display.DPI=96
      Sound.Enabled=0
      Network.Type=1
      CONFIG
      open "$VMDIR"
      open -a "$PARALLELS" "$VMDIR/$NAME.macvm"
      ```
      Take the chance to customize the above settings to your requirements.   
      **At the time of writing, the disk size cannot be altered later.**  
      40GB disk space (see `--disksize` argument) are recommended.  
      32GB disk space are the bare minimum.  
   3. Create a macOS user
   4. Install Parallels Tools and reboot
   5. Install Zscaler
   6. Login
3. Establish connection
   1. Start Zscaler (if not already running)
   2. [Run share-zscaler.sh](#sharing-zscaler)
4. Use connection
   1. On your local machine open a terminal
   2. Paste the host configuration script (that was printed in the previous step) in the terminal and run it

**You can now connect to all hosts you listed in step 2** 🎉

Optionally, you can set the name of your VM in
1. System Preferences → Network → Ethernet → Advanced... → WINS → NetBIOS Name
2. System Preferences → Sharing → Computer Name

## Remote Execution

This section describes the necessary steps to run `share-zscaler.v2.sh` on your
local machine instead of the virtual Zscaler machine using SSH.

### Preparation

#### On your virtual machine
1. Activate SSH by checking System Preferences → Sharing → Remote Login
2. Optionally extend your sudoers so that you may run `sysctl` and `pfctl` without having to enter your password:
   ```shell
   (
   echo "$(whoami) ALL=NOPASSWD: /usr/sbin/sysctl *"
   echo "$(whoami) ALL=NOPASSWD: /sbin/pfctl *"
   ) | sudo tee /etc/sudoers.d/zscaler
   ```
3. Optionally prepare a script with the following contents to lock your screen
   ```bash
   cat << 'LOCK_SCREEN' > ~/Desktop/lock-screen
   #!/bin/bash
   osascript -e 'tell application "System Events" to keystroke "q" using {command down,control down}'
   LOCK_SCREEN
   chmod +x ~/Desktop/lock-screen
   ```
   and run it on login via System Preferences → *Choose your user* → Login items → + → *Select your lock screen script*  
   Don't forget to make it executable using `chmod +x` and to run it once to provide it with sufficient permissions.
4. If the IP of your VPN client machine is dynamic and you can't reliably resolve its IP, a workaround can be to install [GeekTool](https://www.tynsoe.org/geektool/) and display the output of `ipconfig getifaddr en0` in a script Geeklet. At least you now find out the current IP easily.

#### On your local machine

1. [Create an SSH key](https://www.google.com/search?q=create+ssh+key+macos) or use an existing one
2. Copy the public key of your just created key pair to your Zscaler machine:
   ```shell
   ssh-copy-id -i ~/.ssh/id_rsa zscaler@Zscaler.local
   ```
   *This snippet assumes that your Zscaler host has the name `Zscaler` and your user account on that machine is `zscaler`.*
3. Check if you can log in:
   ```shell
   ssh zscaler@Zscaler.local printenv
   ```
   If the output shows the environment variables of your Zscaler host, all is fine.

### Execution

The following command needs to be run on your working machine,
which then connects to the host `Zscaler` with user `zscaler`,
and finishes configuring your working machine using the returned configuration Bash script:
```shell
(
  bash <<'SHARE_ZSCALER_V2'
ssh -4t zscaler@Zscaler.local '
bash -c "$(curl -so- https://raw.githubusercontent.com/bkahlert/kill-zscaler/main/share-zscaler.v2.sh)" -- \
  --probe foo.bar.internal \
  --domain internal
'
SHARE_ZSCALER_V2
) | bash
```

You get prompted for the password of user `zscaler` (unless you did the optional [sudoers configuration](#on-your-virtual-machine)).

> 💡 Users with a VPN host machine with dynamic IP can try to
change the `ssh` command to:
> ```shell
> ssh -4t "zscaler@$(sudo nmap -n -p 22 192.168.206.2-254 -oG - | awk '/Up$/{print $2}')"
> ```
> Be sure to change the `192.168.206` part to match the client's address range.
> The above `nmap` command looks for a machine with an open SSH port and pass the match to the `ssh` command. 

**Example output**:
```
No ALTQ support in kernel
ALTQ related functions disabled
pfctl: pf not enabled
No ALTQ support in kernel
ALTQ related functions disabled
rules cleared
nat cleared
dummynet cleared
0 tables deleted.
0 states cleared
source tracking entries cleared
pf: statistics cleared
pf: interface flags reset
pfctl: Use of -f option, could result in flushing of rules
present in the main ruleset added by the system at startup.
See /etc/pf.conf for further details.

No ALTQ support in kernel
ALTQ related functions disabled
pf enabled

   ▔▔▔▔▔▔▔ SHARE ZSCALER HOST CONFIGURATION

Configuring route to 10ß.200.0.0
route: writing to routing socket: not in table
delete net 100.200.0.0: not in table
add net 100.200.0.0: gateway 192.168.206.14
Configuring resolver for internal
Flushing DNS cache
Host configuration completed ✔
```


## Troubleshooting
- You can run the setup script as many times as you like.
- The output script to run on your local machine updates your name resolution accordingly,
  that is, it updates existing hosts and adds new ones.
- You will very likely have to update `SHARE_ZSCALER_SOURCE_ADDRESS` to the network used by your Parallels installation.
  - You can look it up by opening System Preferences → Network → Ethernet → IP Address
  - As an example: if the screen shows `192.168.42.3` you'll have to use `SHARE_ZSCALER_SOURCE_ADDRESS=192.168.42.0/24`
- If you happen to have no access anymore
  - check if Zscaler is actually connected
  - run (1) your customized `share-zscaler.sh` call on the VM and (2) its output script on your local machine again.
