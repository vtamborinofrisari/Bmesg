#!/bin/bash

function on_message_sent() {
    clear
    echo "CHAT: ${id_chat}"
    cat "${chat_file}"
}

path_to_writer='$HOME/Downloads/writer.sh'

clear
read -p "Connect via bluetooth to the other device. Then press enter" s

file_devices=$(mktemp)
bluetoothctl devices >> "${file_devices}"
count=1
while IFS= read -r line
do
    echo "${count}) ${line}"
    ((count++))
done < <(cat $file_devices)

device_count=$(cat $file_devices | wc -l)
if (( $device_count == 0 ))
then
    echo "You are not connected to any device"
    exit 0
fi
selected=false
while ! $selected
do
    read -p "Select device number to message(Number between 1 and ${device_count}): " device_num
    if (( $device_num < 0 || $device_num > $device_count ))
    then
        echo "You must select a valid device"
    else
        selected=true
        device_MAC=$(cat "${file_devices}" | sed -n ${device_num}p | awk '{print $2}')
        device_name=$(cat "${file_devices}" | sed -n ${device_num}p | awk '{print $3}')
    fi
done
channel_OBEX=$( sdptool browse ${device_MAC} | grep -A 10 "Service Name: File Transfer" | grep Channel | awk '{print $2}' )
if [ "${channel_OBEX}" = '' ]
then
    echo "No channel found. Try unpairing and pairing again the device, then connect and rerun this program"
    read s
    exit 1
fi
read -p "Choose chat ID (The ID must be confidential with the two devices): " id_chat

chat_dir=${HOME}/Downloads/Bmesg/
mkdir -p "${chat_dir}"

chat_file=${HOME}/Downloads/Bmesg/${id_chat}.bmsg
touch "${chat_file}"

export device_MAC
export chat_dir
export id_chat
export chat_file
bmesg_PID=$$
export bmesg_PID
gnome-terminal --title="Send message" --geometry=90x5 -- bash -c "${path_to_writer}"

on_message_sent
trap "on_message_sent" USR1
while true
do
    if [ -f "${HOME}/.cache/obexd/${id_chat}" ]
    then
        echo -n "${device_name}: " >> "${chat_file}"
        cat "${HOME}/.cache/obexd/${id_chat}" >> "${chat_file}"
        clear
        echo "CHAT: ${id_chat}"
        cat "${chat_file}"
        rm "${HOME}/.cache/obexd/${id_chat}"
    fi
    sleep 0.5
done
