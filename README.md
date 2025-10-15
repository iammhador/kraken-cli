# 🦑 Kraken CLI - Complete Setup Guide

This guide will help you set up the Kraken CLI (AWS-like VM launcher) on any Fedora system from scratch.

---

## 📋 Prerequisites

- Fedora Linux (tested on Fedora 40/42)
- Sudo/root access
- Internet connection

---

## 🚀 Step-by-Step Installation

### Step 1: Install Required Packages

```bash
# Update your system
sudo dnf update -y

# Install libvirt, KVM, and Vagrant
sudo dnf install -y @virtualization vagrant vagrant-libvirt

# Install jq (for JSON processing)
sudo dnf install -y jq
```

### Step 2: Start and Enable libvirt Service

```bash
# Start libvirt service
sudo systemctl start libvirtd

# Enable it to start on boot
sudo systemctl enable libvirtd

# Verify it's running
sudo systemctl status libvirtd
```

### Step 3: Configure libvirt Default Network

```bash
# Check if default network exists
sudo virsh net-list --all

# If 'default' network doesn't exist, define it:
sudo virsh net-define /usr/share/libvirt/networks/default.xml

# Start the default network
sudo virsh net-start default

# Enable it to autostart
sudo virsh net-autostart default

# Verify network is active
sudo virsh net-list --all
# Should show: default   active   yes   yes

# Verify virbr0 interface exists
ip link show virbr0
# Should show the interface is UP
```

### Step 4: Add Your User to libvirt Group

```bash
# Add your user to libvirt group
sudo usermod -aG libvirt $USER

# Apply group changes (logout/login or run):
newgrp libvirt

# Verify group membership
groups | grep libvirt
```

### Step 5: Install Kraken CLI

```bash
# Navigate to your Kraken directory (where you have the kraken file)
cd ~/Kraken

# Make kraken executable
chmod +x kraken

# Move it to system PATH
sudo mv kraken /usr/local/bin/

# Or create a symlink (if you want to keep it in your directory)
sudo ln -s ~/Kraken/kraken /usr/local/bin/kraken

# Verify installation
which kraken
kraken
```

---

## ✅ Verify Installation

Run these commands to ensure everything is set up correctly:

```bash
# Check libvirt is running
sudo systemctl status libvirtd

# Check default network is active
sudo virsh net-list --all

# Check virbr0 interface
ip link show virbr0

# Check vagrant is installed
vagrant --version

# Check kraken is accessible
kraken
```

---

## 🎯 Usage Examples

### Launch Your First Instance

```bash
kraken init
```

Follow the interactive prompts:
1. Choose **[1] libvirt/KVM** (recommended)
2. Choose your OS (e.g., **[1] Ubuntu 22.04 LTS**)
3. Configure CPU (e.g., **[2] Use default (2 cores)**)
4. Configure RAM (e.g., **[2] Use default (2048 MB)**)
5. Configure Storage (e.g., **[1] Use default (20 GB)**)
6. Choose Network (e.g., **[1] NAT**)
7. Enter instance name (e.g., **my-first-vm**)
8. Confirm launch: **y**

Wait for the VM to launch (may take a few minutes for first-time box download).

### Manage Instances

```bash
# List all instances
kraken list

# SSH into an instance
kraken ssh my-first-vm

# Check instance status
kraken status my-first-vm

# Stop an instance (pause, keep files)
kraken stop my-first-vm

# Start a stopped instance
kraken start my-first-vm

# Destroy an instance (permanently delete)
kraken destroy my-first-vm
```

### Inside the VM - Verification Commands

Once you SSH into a VM, verify it's working:

```bash
# System info
cat /etc/os-release
hostname
uptime

# Check resources
nproc          # CPU cores
free -h        # RAM
df -h          # Disk space

# Test internet connectivity
ping -c 4 google.com
curl -I https://www.google.com

# Update packages
sudo apt update
sudo apt install -y curl wget htop

# Exit the VM
exit
```

---

## 🔧 Troubleshooting

### Issue 1: "Network not found: default"

**Solution:**
```bash
sudo virsh net-define /usr/share/libvirt/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default
```

### Issue 2: "failed to get mtu of bridge virbr0"

**Solution:**
```bash
sudo systemctl restart libvirtd
sudo virsh net-start default
ip link show virbr0  # Verify it's UP
```

### Issue 3: Permission denied errors

**Solution:**
```bash
sudo usermod -aG libvirt $USER
newgrp libvirt
# Or logout and login again
```

### Issue 4: Vagrant box download is slow

**Solution:** First download is always slow. Subsequent VMs will use cached box.

```bash
# Check cached boxes
vagrant box list
```

### Issue 5: "kraken: command not found"

**Solution:**
```bash
# Verify kraken is in PATH
which kraken

# If not, reinstall:
sudo cp ~/Kraken/kraken /usr/local/bin/
sudo chmod +x /usr/local/bin/kraken
```

---

## 📁 File Locations

```
/usr/local/bin/kraken                    # Kraken CLI binary
~/.kraken/instances/                     # All VM instances
~/.kraken/instances/<name>/Vagrantfile   # VM configuration
~/.kraken/instances/<name>/kraken-config.json  # Instance config
~/.vagrant.d/boxes/                      # Cached Vagrant boxes
~/kvm_images/                            # VM disk images
```

---

## 🗑️ Cleanup / Uninstall

### Remove Kraken CLI

```bash
sudo rm /usr/local/bin/kraken
rm -rf ~/.kraken
```

### Remove a specific instance

```bash
kraken destroy <instance-name>
```

### Remove all instances

```bash
rm -rf ~/.kraken/instances/*
```

### Remove cached Vagrant boxes

```bash
vagrant box list
vagrant box remove <box-name>
```

### Complete removal (including libvirt)

```bash
# Stop all VMs
sudo virsh list --all
sudo virsh destroy <vm-name>
sudo virsh undefine <vm-name>

# Remove libvirt and vagrant
sudo dnf remove vagrant vagrant-libvirt @virtualization

# Remove data
rm -rf ~/.kraken
rm -rf ~/.vagrant.d
sudo rm -rf ~/kvm_images
```

---

## 💡 Tips & Best Practices

1. **First Launch is Slow**: The first time you create a VM with a specific OS, Vagrant downloads the box image (~500MB-1GB). Subsequent VMs with the same OS are much faster.

2. **Resource Allocation**: Don't allocate all your system resources. Leave some for your host OS.
   - CPU: Leave at least 2 cores for host
   - RAM: Leave at least 4GB for host
   - Example: If you have 12 cores and 16GB RAM, allocate max 8 cores and 8GB to VMs

3. **Network Modes**:
   - **NAT**: VM can access internet, can't be accessed from outside (default, safest)
   - **Bridged**: VM gets IP on your local network (accessible from LAN)
   - **Private**: VM isolated, only accessible from host

4. **Stop vs Destroy**:
   - **Stop**: Pauses the VM, saves state, can restart later
   - **Destroy**: Permanently deletes the VM and all data

5. **Backup Important Data**: VMs are isolated. If you destroy a VM, all data inside is lost. Always backup important files to your host.

6. **Check Before Creating**: Run `kraken list` before creating new instances to see what's already running.

---

## 🎓 Quick Reference

```bash
# Create new VM
kraken init

# List VMs
kraken list

# Access VM
kraken ssh <name>

# Stop VM
kraken stop <name>

# Start VM
kraken start <name>

# Delete VM
kraken destroy <name>

# Check status
kraken status <name>
```

---

## 🔄 Quick Setup Script

Save this as `setup-kraken.sh` for future installations:

```bash
#!/bin/bash
# Kraken CLI Setup Script

echo "🦑 Setting up Kraken CLI..."

# Install packages
sudo dnf install -y @virtualization vagrant vagrant-libvirt jq

# Start services
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Configure network
sudo virsh net-define /usr/share/libvirt/networks/default.xml 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default

# Add user to group
sudo usermod -aG libvirt $USER

# Install kraken (assuming it's in current directory)
sudo cp kraken /usr/local/bin/
sudo chmod +x /usr/local/bin/kraken

echo "✅ Setup complete!"
echo "⚠️  Please logout and login again to apply group changes"
echo "Then run: kraken init"
```

---

## 📞 Support

If you encounter issues:

1. Check libvirt status: `sudo systemctl status libvirtd`
2. Check network status: `sudo virsh net-list --all`
3. Check logs: `journalctl -xe | grep libvirt`
4. Verify groups: `groups`

---

## 🎉 You're Ready!

Your Kraken CLI is now set up and ready to launch VMs. Start with:

```bash
kraken init
```

Enjoy your AWS-like VM management experience! 🚀