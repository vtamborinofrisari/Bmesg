#!/bin/bash

while true
do
    clear
    read -p "Input message (Press Enter to send): " message
    message_file=${chat_dir}${id_chat}
    touch "${message_file}"
    echo "${message}" >> "${message_file}"
    obexftp --bluetooth "${device_MAC}" --channel 10 --put ${message_file} 2> /tmp/trash_bmesg
    echo -e "You: ${message}" >> ${chat_file}
    rm "${message_file}"
    #bmesg_PID=$( ps aux | grep bmesg.sh | awk '{print $2}' )
    kill -USR1 $bmesg_PID
done
