#!/bin/bash
# Minecraft Server Permissions Fix Script - James A. Chambers - https://jamesachambers.com/minecraft-bedrock-edition-ubuntu-dedicated-server-guide/

# Takes ownership of server files to fix common permission errors such as access denied
# This is very common when restoring backups, moving and editing files, etc.

# If you are using the systemd service (sudo systemctl start servername) it performs this automatically for you each startup

is_docker=""

if [ "isdocker" == "yes" ]; then
  is_docker="yes"
else
  is_docker="no"
fi

# Set path variable
USERPATH="pathvariable"
PathLength=${#USERPATH}
if [[ "$PathLength" -gt 12 ]]; then
  PATH="$USERPATH"
else
  echo "Unable to set path variable."
  echo "You likely need to download an updated version of SetupMinecraft.sh from GitHub!"
fi

echo "Taking ownership of all server files/folders in dirname/minecraftbe/servername..."
if [ "$is_docker" != "yes" ]; then
  sudo -n chown -R userxname dirname/minecraftbe/servername
  sudo -n chmod -R 755 dirname/minecraftbe/servername/*.sh
  if [ -e dirname/minecraftbe/servername/bedrock_server ]; then
    sudo -n chmod 755 dirname/minecraftbe/servername/bedrock_server
    sudo -n chmod +x dirname/minecraftbe/servername/bedrock_server
  fi
elif [ "$is_docker" == "yes" ]; then
  chown -R userxname dirname/minecraftbe/servername
  chmod -R 755 dirname/minecraftbe/servername/*.sh
  if [ -e dirname/minecraftbe/servername/bedrock_server ]; then
    chmod 755 dirname/minecraftbe/servername/bedrock_server
    chmod +x dirname/minecraftbe/servername/bedrock_server
  fi
fi

echo "Complete"
