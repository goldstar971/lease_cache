CLAM_path=$(pwd);
echo "export CLAM_path=$CLAM_path" >> ~/.bashrc

echo "if [ -f $CLAM_path/CLAM_bash_functions.sh ]; then" >> ~/.bashrc
echo "	. $CLAM_path/CLAM_bash_functions.sh" >> ~/.bashrc
echo "fi" >> ~/.bashrc 

