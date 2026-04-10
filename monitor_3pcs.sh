#!/bin/bash

# Script para monitorear 3 PCs simultáneamente
# Abre una sesión tmux con 3 ventanas

# Credenciales
PC1_USER="estudiante"
PC1_HOST="10.43.99.128"
PC1_PASS="0r4nGut4n*24"

PC2_USER="estudiante"
PC2_HOST="10.43.100.144"
PC2_PASS="Juan.2005"

PC3_USER="estudiante"
PC3_HOST="10.43.100.90"
PC3_PASS="Canguro-21Nu"

# Crear función para conectar con expect
connect_and_run() {
    local user=$1
    local host=$2
    local pass=$3
    local cmd=$4
    local name=$5

    echo "[${name}] Conectando a ${user}@${host}..."

    expect <<EOF
        set timeout -1
        spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${user}@${host}
        expect "password:"
        send "${pass}\r"
        expect "\$"
        send "cd ~/trafico_urbano && ${cmd}\r"
        interact
EOF
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Monitor de 3 PCs - Tráfico Urbano                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Se abrirán 3 conexiones. Presiona Ctrl+C en cualquiera para salir."
echo ""

# Lanzar PC1 en background
(connect_and_run "${PC1_USER}" "${PC1_HOST}" "${PC1_PASS}" \
  "bash lanzar_pc1.sh && echo '---PC1 LANZADO---' && tail -f logs/broker.log logs/cam_C5.log logs/gps_C5.log" "PC1") &
PC1_PID=$!

# Pequeño delay
sleep 1

# Lanzar PC2 en background
(connect_and_run "${PC2_USER}" "${PC2_HOST}" "${PC2_PASS}" \
  "bash lanzar_pc2.sh && echo '---PC2 LANZADO---' && tail -f logs/analitica.log logs/semaforos.log logs/bd_replica.log" "PC2") &
PC2_PID=$!

# Pequeño delay
sleep 1

# Lanzar PC3 en background
(connect_and_run "${PC3_USER}" "${PC3_HOST}" "${PC3_PASS}" \
  "bash lanzar_pc3.sh && echo '---PC3 LANZADO---' && tail -f logs/bd_principal.log" "PC3") &
PC3_PID=$!

echo "✓ 3 conexiones iniciadas (PIDs: ${PC1_PID}, ${PC2_PID}, ${PC3_PID})"
echo "✓ Monitorea la salida arriba"
echo ""

# Esperar a que alguno se termine
wait $PC1_PID $PC2_PID $PC3_PID
