echo "setting up research path variable"
CLAM_path=$(pwd);
echo "export CLAM_path=$CLAM_path">>~/.bashrc

echo "installing export_fig library for matlab"
git clone https://github.com/altmany/export_fig.git "$CLAM_path/MATLAB_data_visualizations/export_fig"

echo "adding bash functions to bashrc"
echo "if [ -f $CLAM_path/CLAM_bash_functions.sh ]; then">> ~/.bashrc
echo "	. $CLAM_path/CLAM_bash_functions.sh">> ~/.bashrc
echo "fi" >> ~/.bashrc 

echo "installing libpng12 which is necessasry for quartus to work"
sudo add-apt-repository ppa:linuxuprising/libpng12
sudo apt update
sudo apt install libpng12-0

echo "installing GNU RISCV-Embedded GCC"
sudo apt install npm
sudo npm install --global xpm@latest
xpm install --global @xpack-dev-tools/riscv-none-embed-gcc@8.3.0-2.3.1 --verbose

echo "setting USB blaster device files"
cat > 51−usbblaster.rules<< EOF
"# USB-Blaster"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="0666"
"SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6002", MODE="0666"

SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6003", MODE="0666"

# USB-Blaster II
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6810", MODE="0666"
EOF
sudo mv ./51−usbblaster.rules /etc/udev/rules.d/51−usbblaster.rules

echo "install rust and rust cargo package manager"
curl https://sh.rustup.rs -sSf | sh
echo . "$HOME/.cargo/env" >> ~/.bashrc
