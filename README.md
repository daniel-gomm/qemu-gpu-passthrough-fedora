# qemu-gpu-passthrough-fedora
A script for simplifying adding kernels for (NVIDIA) GPU passthrough for qemu to grub under fedora. The script makes adding and managing GPU passthough kernels straight forward.

## Quick Start

### Installation

The entire logic is captured in the bash script [gpu_passthrough_update.bash](./gpu_passthrough_update.bash). You can download the script and run it from the terminal or use the installer to simplify the usage: 

To install the script using the installer run:

```bash
curl -fsSL https://raw.githubusercontent.com/daniel-gomm/qemu-gpu-passthrough-fedora/main/INSTALL.sh | bash
```

Then restart your terminal or run:
```bash
source ~/.bashrc  # or ~/.zshrc for zsh
```

### Usage

After installation, simply run:

```bash
gpu-passthrough
```

The script will guide you through setting up a GPU passthrough kernel for QEMU/KVM.

## What is GPU Passthrough?

GPU passthrough allows you to dedicate your physical GPU (or one of your GPUs in a multi-GPU setup) directly to a virtual machine. This enables near-native graphics performance in VMs, which is particularly useful for:

- Running GPU-intensive applications in VMs (gaming, 3D rendering, CAD)
- Testing GPU drivers in isolated environments
- Running Windows applications that require dedicated graphics on a Linux host
- Development and testing of GPU-accelerated software

## What This Script Does

Setting up GPU passthrough on Fedora requires specific kernel parameters and driver configurations. This script automates the process by:

1. **Cloning your current kernel** - Creates a duplicate boot entry so you can switch between passthrough and normal modes
2. **Blacklisting GPU drivers** - Prevents the host system from loading NVIDIA/Nouveau drivers on the passthrough kernel
3. **Configuring VFIO** - Sets up VFIO-PCI to bind your GPU for passthrough
4. **Setting IOMMU parameters** - Enables and configures IOMMU based on your CPU (Intel/AMD)
5. **Managing boot entries** - Allows you to set which kernel boots by default
6. **Updating dracut** - Configures the initial ramdisk with VFIO drivers (first-time setup)
7. **Remembering your settings** - Stores your configuration in `~/.config/gpu-passthrough` for easy updates

### What You'll Need

- Your CPU manufacturer (Intel or AMD)
- VFIO PCI IDs of your GPU and its audio controller (the script guides you through finding these)

The script will prompt you for this information and remember it for future runs, making it easy to update your passthrough kernel after system updates.

## Background

This script is based on the excellent guide and scripts from [br0kenpixel/fedora-qemu-gpu-passthrough](https://github.com/br0kenpixel/fedora-qemu-gpu-passthrough), which provides detailed manual instructions for setting up GPU passthrough on Fedora. This automated version streamlines the process into a single interactive script that handles the complexity while keeping your configuration portable and updateable.

## System Requirements

- Fedora-based Linux distribution (tested on Fedora 43 Workstation Edition)
- NVIDIA GPU (script targets NVIDIA, but principles apply to other GPUs)
- CPU with IOMMU/VT-d (Intel) or AMD-Vi (AMD) support
- IOMMU enabled in BIOS/UEFI

## License

This project is licensed under the [MIT License](LICENSE)
