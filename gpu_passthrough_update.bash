#!/bin/bash

DEFAULTS_SAVE_PATH='./.gpu_passthrough_defaults.txt'


RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

load_default() {
    local key="$1"
    grep -oP "${key}=\K.*" --max-count=1 "$DEFAULTS_SAVE_PATH"
}


echo -e "
${CYAN}########################################################
NVIDIA GPU Passthrough Kernel Helper
########################################################${NC}

This helper script is designed for the use with ${RED}QEMU/KVM${NC} for ${RED}Fedora-based systems${NC}.
Tested on Fedora 43 (Workstation Edition). ${RED}Do not use this script on other systems.${NC}
"

# Load cached defaults if available
if test -f "./.gpu_passthrough_defaults.txt"; then
	PREVIOUS_PASSTHROUGH_KERNEL=$(load_default CURRENT_PASSTHROUGH_KERNEL)
	CPU_MANUFACTURER=$(load_default CPU_MANUFACTURER)
	VFIO_PCI_IDS=$(load_default VFIO_PCI_IDS)
fi

# Load current default kernel details
DEFAULT_KERNEL=$(sudo grubby --default-kernel)
DEFAULT_INITRD=$(sudo grubby --info=$DEFAULT_KERNEL | grep -oP 'initrd="\K[^"]+' --max-count=1)
GPU_PASSTHROUGH_NAME="$(sudo grubby --default-title) [KVM GPU Passthrough]"


# Get user input for CPU manufacturer
if [ -n "$CPU_MANUFACTURER" ]; then
	read -p "Your CPU manufacturer is set to \"$CPU_MANUFACTURER\". Is this correct? (Y/n): " OPTION
	if [[ "${OPTION^^}" == "N"  ]]; then
		CPU_MANUFACTURER=""
	fi
fi


while [[ ! "$CPU_MANUFACTURER" =~ ^(AMD|INTEL)$ ]]; do
    read -p "Please enter the CPU manufacturer (INTEL/AMD): " CPU_MANUFACTURER
done


# Get user input for VFIO PCI IDs
if [ -n "$VFIO_PCI_IDS" ]; then
        read -p "Your VFIO PCI IDs are set to \"$VFIO_PCI_IDS\". Is this correct? (Y/n): " OPTION
        if [[ "${OPTION^^}" == "N"  ]]; then
                VFIO_PCI_IDS=""
        fi
fi

while test -z "$VFIO_PCI_IDS"; do
	echo -n -e "
Locate the VFIO PCI IDs of your GPU and it's audio controller (for some GPU's there is no separate audio controller).
To do this, you can run ${CYAN}lspci -vvnn${NC}, locate your GPU and check its IOMMU group. Check the other devices and see if there are other device in the IOMMU group, which should be the audio controller. Get the VFIO PCI IDs of all devices in the IOMMU group from the first line of their entries (without the brackets, e.g., '10ce:25a1'). For instance:
	${CYAN}01:00.0 3D controller [0302]: NVIDIA Corporation GA107M [GeForce RTX 3050 Mobile] [${RED}10ce:25a1${CYAN}] (rev a1)${NC}

Please enter the VFIO PCI IDs of your GPU and it's audio controller (for some GPU's there is no separate audio controller). The IDs must be comma (,) separated without spaces in between: "
	read VFIO_PCI_IDS
done


# Display overview of settings to be applied
echo -e "
${RED}Creating new GPU Passthrough Kernel with options:${NC}

Name: ${CYAN}$GPU_PASSTHROUGH_NAME${NC}
Kernel: ${CYAN}$DEFAULT_KERNEL${NC}
CPU Manufacturer: ${CYAN}$CPU_MANUFACTURER${NC}
VFIO PCI IDs: ${CYAN}$VFIO_PCI_IDS${NC}
"

read -p "Continue (y/N): " OPTION
if [[ ! "${OPTION^^}" == "Y"  ]]; then
	echo -e "${RED}GPU Passthrough Kernel creation cancelled.${NC}"
	exit 0
fi


echo -e "${GREEN}Cloning default Kernel...${NC}"
sudo grubby --grub2 --add-kernel=$DEFAULT_KERNEL --initrd=$DEFAULT_INITRD --copy-default --title="${GPU_PASSTHROUGH_NAME}"

echo -e "${GREEN}Updating Kernel Arguments (1/2)...${NC}"
sudo grubby --update-kernel=0 --args="rd.driver.blacklist=nouveau,nvidia,nvidiafb,nvidia-gpu modprobe.blacklist=nouveau,nvidia,nvidiafb,nvidia-gpu"

if [[ "$CPU_MANUFACTURER" == "AMD"  ]]; then
	CPU_ARG="amd_iommu"
else
	CPU_ARG="intel_iommu"
fi

echo -e "${GREEN}Updating Kernel Arguments (2/2)...${NC}"
sudo grubby --update-kernel=0 --args="video=efifb:off $CPU_ARG=on rd.driver.pre=vfio-pci kvm.ignore_msrs=1 vfio-pci.ids=$VFIO_PCI_IDS"

read -p "Select GPU Passthrough kernel as grub default (y/N): " OPTION
if [[ ! "${OPTION^^}" == "Y"  ]]; then
	sudo grubby --set-default-index=1
fi

if [ -n "$PREVIOUS_PASSTHROUGH_KERNEL" ]; then
	echo -n -e "${RED}Delete old GPU Passthrough Kernel $PREVIOUS_PASSTHROUGH_KERNEL (Y/n):  ${NC}"
	read OPTION
	if [[ ! "${OPTION^^}" == "N"  ]]; then
		entries=$(sudo grubby --info=ALL | grep "index=" | wc -l)
		for ((i=0; i<entries; i++)); do
			if [[ $(sudo grubby --info=$i | grep "title=\"$PREVIOUS_PASSTHROUGH_KERNEL\"" | wc -l) == "1" ]]; then
				echo -e "${RED}Deleting Kernel $PREVIOUS_PASSTHROUGH_KERNEL...${NC}"
				sudo grubby --remove-kernel=$i
				break
			fi
		done
	fi
else
	echo -e "
	If this is the first time that you add a GPU passthrough kernel you have to update the dracut configuration.
	${RED}Is this the first time that you are adding a GPU Passthrough kernel (y/N): ${NC}"
	read OPTION
        if [[ "${OPTION^^}" == "Y"  ]]; then
                # Edit dracut config
		echo -e "${GREEN}Updating dracut...${NC}"
		sudo echo "add_drivers+=\" vfio vfio_iommu_type1 vfio_pci \"" >> /etc/dracut.conf.d/local.conf
		sudo dracut -f kver $(uname -r)
	fi
fi


# Save defaults to file
echo "CURRENT_PASSTHROUGH_KERNEL=$GPU_PASSTHROUGH_NAME" > $DEFAULTS_SAVE_PATH
echo "CPU_MANUFACTURER=$CPU_MANUFACTURER" >> $DEFAULTS_SAVE_PATH
echo "VFIO_PCI_IDS=$VFIO_PCI_IDS" >> $DEFAULTS_SAVE_PATH

echo -e "${GREEN}Script ran successfully!${NC} Reboot your system and select the correct kernel to use GPU Passthrough."
