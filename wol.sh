#!/bin/bash

# Ottieni il nome dell'interfaccia di rete principale (evita loopback e virbr)
INTERFACCIA=$(ip -o link show | awk -F': ' '{print $2}' | grep -vE 'lo|virbr|docker|vmbr' | head -n1)

# Verifica se l'interfaccia è stata trovata
if [ -z "$INTERFACCIA" ]; then
    echo "Errore: Nessuna interfaccia di rete valida trovata."
    exit 1
fi

# Ottieni il MAC address dell'interfaccia
MAC=$(cat /sys/class/net/$INTERFACCIA/address)

# Nome file .link (usiamo il nome dell'interfaccia)
LINK_FILE="/etc/systemd/network/10-${INTERFACCIA}.link"

# Crea il file .link con configurazione WoL
cat <<EOF > "$LINK_FILE"
[Match]
MACAddress=$MAC

[Link]
WakeOnLan=magic
EOF

echo "File $LINK_FILE creato con successo."

# Forza il reload di systemd per rilevare il nuovo .link file (opzionale)
udevadm control --reload
udevadm trigger

# Riavvia il sistema per rendere effettiva la modifica
echo "Riavvio della macchina tra 5 secondi..."
sleep 5
reboot
