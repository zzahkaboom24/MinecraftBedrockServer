#!/bin/bash
# James Chambers - https://jamesachambers.com/minecraft-bedrock-edition-ubuntu-dedicated-server-guide/
# Minecraft Bedrock Server restart script

# Set path variable
USERPATH="pathvariable"
PathLength=${#USERPATH}
if [[ "$PathLength" -gt 12 ]]; then
  PATH="$USERPATH"
else
  echo "Unable to set path variable."
  echo "You likely need to download an updated version of SetupMinecraft.sh from GitHub!"
fi

# Check to make sure we aren't running as root
if [[ $(id -u) = 0 ]]; then
  echo "This script is not meant to be run as root."
  echo "Please run ./restart.sh as a non-root user, without sudo."
  echo "Exiting..."
  exit 1
fi

# Check if server is started
if [ "viewmanager" == "screen" ]; then
  if ! screen -list | grep -q '\.servername\s'; then
    echo "Server is not currently running!"
    exit 1
  fi
elif [ "viewmanager" == "tmux" ]; then
  if ! tmux list-sessions -F "#{session_name} #{window_name} (created #{session_created})" | awk -F " " '{printf "%s: %s (%s)\n", $1, $2, strftime("%Y-%m-%d %H:%M:%S", $4)}' | sed 's/ (created [0-9]*)//' | tr -s ' ' | grep -q "^servername: console"; then
    echo "Server is not currently running!"
    exit 1
  fi
fi

echo "Sending restart notifications to server..."

# Start countdown notice on server
if [ "viewmanager" == "screen" ]; then
  screen -Rd servername -X stuff "say Server is restarting in 30 seconds! $(printf '\r')"
  sleep 23s
  screen -Rd servername -X stuff "say Server is restarting in 7 seconds! $(printf '\r')"
  sleep 1s
  screen -Rd servername -X stuff "say Server is restarting in 6 seconds! $(printf '\r')"
  sleep 1s
  screen -Rd servername -X stuff "say Server is restarting in 5 seconds! $(printf '\r')"
  sleep 1s
  screen -Rd servername -X stuff "say Server is restarting in 4 seconds! $(printf '\r')"
  sleep 1s
  screen -Rd servername -X stuff "say Server is restarting in 3 seconds! $(printf '\r')"
  sleep 1s
  screen -Rd servername -X stuff "say Server is restarting in 2 seconds! $(printf '\r')"
  sleep 1s
  screen -Rd servername -X stuff "say Server is restarting in 1 second! $(printf '\r')"
  sleep 1s
  screen -Rd servername -X stuff "say Closing server...$(printf '\r')"
  screen -Rd servername -X stuff "stop$(printf '\r')"
elif [ "viewmanager" == "tmux" ]; then
  tmux send-keys -t servername:0.0 "say Server is restarting in 30 seconds!" C-m
  sleep 23s
  tmux send-keys -t servername:0.0 "say Server is restarting in 7 seconds!" C-m
  sleep 1s
  tmux send-keys -t servername:0.0 "say Server is restarting in 6 seconds!" C-m
  sleep 1s
  tmux send-keys -t servername:0.0 "say Server is restarting in 5 seconds!" C-m
  sleep 1s
  tmux send-keys -t servername:0.0 "say Server is restarting in 4 seconds!" C-m
  sleep 1s
  tmux send-keys -t servername:0.0 "say Server is restarting in 3 seconds!" C-m
  sleep 1s
  tmux send-keys -t servername:0.0 "say Server is restarting in 2 seconds!" C-m
  sleep 1s
  tmux send-keys -t servername:0.0 "say Server is restarting in 1 second!" C-m
  sleep 1s
  tmux send-keys -t servername:0.0 "say Closing server..." C-m
  tmux send-keys -t servername:0.0 'stop' C-m
fi

echo "Closing server..."
# Wait up to 30 seconds for server to close
StopChecks=0
while [[ $StopChecks -lt 30 ]]; do
  if [ "viewmanager" == "screen" ]; then
    if ! screen -list | grep -q '\.servername\s'; then
      break
    fi
    sleep 1
    StopChecks=$((StopChecks + 1))
  elif [ "viewmanager" == "tmux" ]; then
    if ! tmux list-sessions -F "#{session_name} #{window_name} (created #{session_created})" 2>/dev/null | awk -F " " '{printf "%s: %s (%s)\n", $1, $2, strftime("%Y-%m-%d %H:%M:%S", $4)}' | sed 's/ (created [0-9]*)//' | tr -s ' ' | grep -q "^servername: console"; then
      break
    fi

    # Checking the last line in the specified tmux pane for the output: Quit correctly; then killing the tmux session for the server if the statement is successful
    second_last_line=$(tmux capture-pane -pS -1 -t servername:0.0 | awk '{line2=line1; line1=$0} END{print line2}')
    third_last_line=$(tmux capture-pane -pS -2 -t servername:0.0 | awk '{line3=line2; line2=line1; line1=$0} END{print line3}')
    if [ "$second_last_line" == "Quit correctly" ] || [ "$third_last_line" == "Quit correctly" ]; then
        # Sleep for one second before killing the session
        sleep 1
        tmux kill-session -t servername
        break
    fi

    sleep 1
    StopChecks=$((StopChecks + 1))
  fi
done

if [ "viewmanager" == "screen" ]; then
  if screen -list | grep -q '\.servername\s'; then
    # Server still hasn't stopped after 30s, tell Screen to close it
    echo "Minecraft server still hasn't closed after 30 seconds, closing screen manually"
    screen -S servername -X quit
    sleep 10
  fi
elif [ "viewmanager" == "tmux" ]; then
  if tmux list-sessions -F "#{session_name} #{window_name} (created #{session_created})" 2>/dev/null | awk -F " " '{printf "%s: %s (%s)\n", $1, $2, strftime("%Y-%m-%d %H:%M:%S", $4)}' | sed 's/ (created [0-9]*)//' | tr -s ' ' | grep -q "^servername: console"; then
    # Server still hasn't stopped after 30s, tell Tmux to close it
    echo "Minecraft server still hasn't closed after 30 seconds, closing tmux manually"
    tmux kill-session -t servername
    sleep 10
  fi
fi

# Start server (start.sh) - comment out if you want to use systemd and have added a line to your sudoers allowing passwordless sudo for the start command using 'sudo visudo' and insert the example line below with the correct username
#/bin/bash dirname/minecraftbe/servername/start.sh

# EXAMPLE SUDO LINE
# minecraftuser ALL=(ALL) NOPASSWD: /bin/systemctl start yourservername

# If you have added the above example sudo line to your sudoers file with 'sudo visudo' and the correct username uncomment the line below (make sure you comment out the /bin/bash dirname/minecraftbe/servername/start.sh line)

if [ "tmux" == "screen" ]; then
  echo "Starting Minecraft server."
  echo "To view window type screen -r servername"
  echo "To minimize the window and let the server run in the background, press Ctrl+A then Ctrl+D"
  sudo -n systemctl start servername
elif [ "tmux" == "tmux" ]; then
  echo "Starting Minecraft server."
  echo "To view window type tmux attach -t servername:0.0"
  echo "To minimize the window and let the server run in the background, press Ctrl+B+D"
  sudo -n systemctl start servername
fi
