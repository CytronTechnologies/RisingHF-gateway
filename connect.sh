#! /bin/bash

# Exit the script if internet loss connection detected

SERVICE=ttn-gateway.service

while [[ $(systemctl is-failed $SERVICE) == "active" ]]; do
  # echo "Scheduled check on Internet connection..."
  if [[ $(ping -c1 google.com 2>&1 | grep " 0% packet loss") == "" ]]; then
   echo "[TTN Gateway]: Internet connection loss..."
   if [[ $(systemctl is-failed $SERVICE) == "active" ]]; then
    echo "Restarting ttn-gateway service"
    systemctl restart ttn-gateway & echo "Exiting connect program" & exit 0
   fi
  fi  
  sleep 30
done
