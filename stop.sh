#!/bin/bash
# James Chambers - https://jamesachambers.com/minecraft-bedrock-edition-ubuntu-dedicated-server-guide/
# Minecraft Server stop script - primarily called by minecraft service but can be ran manually

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
  echo "Please run ./stop.sh as a non-root user, without sudo."
  echo "Exiting..."
  exit 1
fi

# Check if server is running
if [ "viewmanager" == "screen" ]; then
  if ! screen -list | grep -q '\.servername\s'; then
    echo "Server is not currently running!"
    exit 1
  fi
elif [ "viewmanager" == "tmux" ]; then
  if ! tmux list-sessions -F "#{session_name} #{window_name} (created #{session_created})" 2>/dev/null | awk -F " " '{printf "%s: %s (%s)\n", $1, $2, strftime("%Y-%m-%d %H:%M:%S", $4)}' | sed 's/ (created [0-9]*)//' | tr -s ' ' | grep -q "^servername: console"; then
    echo "Server is not currently running!"
    exit 1
  fi
fi

# Get an optional custom countdown time (in minutes)
CountdownTime=0
while getopts ":t:" opt; do
  case $opt in
  t)
    case $OPTARG in
    '' | *[!0-9]*)
      echo "Countdown time must be a whole number in minutes."
      exit 1
      ;;
    *)
      CountdownTime=$OPTARG >&2
      ;;
    esac
    ;;
  \?)
    echo "Invalid option: -$OPTARG"
    echo "Countdown time must be a whole number in minutes." >&2
    ;;
  esac
done

# Stop the server
while [[ $CountdownTime -gt 0 ]]; do
  if [[ $CountdownTime -eq 1 ]]; then
    if [ "viewmanager" == "screen" ]; then
      screen -Rd servername -X stuff "say Stopping server in 60 seconds...$(printf '\r')"
      echo "Stopping server in 60 seconds..."
      sleep 30
      screen -Rd servername -X stuff "say Stopping server in 30 seconds...$(printf '\r')"
      echo "Stopping server in 30 seconds..."
      sleep 20
      screen -Rd servername -X stuff "say Stopping server in 10 seconds...$(printf '\r')"
      echo "Stopping server in 10 seconds..."
      sleep 10
      CountdownTime=$((CountdownTime - 1))
    elif [ "viewmanager" == "tmux" ]; then
      tmux send-keys -t servername:0.0 "say Stopping server in 60 seconds..." C-m
      echo "Stopping server in 60 seconds..."
      sleep 30
      tmux send-keys -t servername:0.0 "say Stopping server in 30 seconds..." C-m
      echo "Stopping server in 30 seconds..."
      sleep 20
      tmux send-keys -t servername:0.0 "say Stopping server in 10 seconds..." C-m
      echo "Stopping server in 10 seconds..."
      sleep 10
      CountdownTime=$((CountdownTime - 1))
    fi
  else
    if [ "viewmanager" == "screen" ]; then
      screen -Rd servername -X stuff "say Stopping server in $CountdownTime minutes...$(printf '\r')"
      echo "Stopping server in $CountdownTime minutes...$(printf '\r')"
      sleep 60
      CountdownTime=$((CountdownTime - 1))
    elif [ "viewmanager" == "tmux" ]; then
      tmux send-keys -t servername:0.0 "say Stopping server in $CountdownTime minutes..." C-m
      echo "Stopping server in $CountdownTime minutes...$(printf '\r')"
      sleep 60
      CountdownTime=$((CountdownTime - 1))
    fi
  fi
  echo "Waiting for $CountdownTime more minutes ..."
done
echo "Stopping Minecraft server ..."

if [ "viewmanager" == "screen" ]; then
  screen -Rd servername -X stuff "say Stopping server (stop.sh called)...$(printf '\r')"
  screen -Rd servername -X stuff "stop$(printf '\r')"
elif [ "viewmanager" == "tmux" ]; then
  tmux send-keys -t servername:0.0 "say Stopping server (stop.sh called)..." C-m
  tmux send-keys -t servername:0.0 'stop' C-m
fi

# Wait up to 20 seconds for server to close
StopChecks=0
while [[ $StopChecks -lt 20 ]]; do
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

# Force quit if server is still open
if [ "viewmanager" == "screen" ]; then
  if screen -list | grep -q '\.servername\s'; then
    echo "Minecraft server still hasn't stopped after 20 seconds, closing screen manually"
    screen -S servername -X quit
  fi
elif [ "viewmanager" == "tmux" ]; then
  if tmux list-sessions -F "#{session_name} #{window_name} (created #{session_created})" 2>/dev/null | awk -F " " '{printf "%s: %s (%s)\n", $1, $2, strftime("%Y-%m-%d %H:%M:%S", $4)}' | sed 's/ (created [0-9]*)//' | tr -s ' ' | grep -q "^servername: console"; then
    echo "Minecraft server still hasn't stopped after 20 seconds, closing screen manually"
    tmux kill-session -t servername
  fi
fi

echo "Minecraft server servername stopped."
