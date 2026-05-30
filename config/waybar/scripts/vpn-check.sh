#!/bin/bash
if [[ $(ip a | grep wg0 | grep -c inet) -eq 1 ]]; then
  echo '{"text":"Connected", "class":"connected", "percentage":100}'
else 
  echo '{"text":"Disconnected", "class":"disconnected", "percentage":0}'
fi 
