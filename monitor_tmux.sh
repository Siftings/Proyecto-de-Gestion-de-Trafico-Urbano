#!/bin/bash

# Script para monitorear 3 PCs con tmux
# Cada PC en su propia ventana

SESSION="trafico_3pcs"

# Crear sesión tmux
tmux new-session -d -s $SESSION -n "PC1"

# Ventana PC1
tmux send-keys -t $SESSION:PC1 "ssh -o StrictHostKeyChecking=no estudiante@10.43.99.128" C-m
sleep 1
tmux send-keys -t $SESSION:PC1 "cd ~/trafico_urbano && bash lanzar_pc1.sh" C-m

# Ventana PC2
tmux new-window -t $SESSION -n "PC2"
tmux send-keys -t $SESSION:PC2 "ssh -o StrictHostKeyChecking=no estudiante@10.43.100.144" C-m
sleep 1
tmux send-keys -t $SESSION:PC2 "cd ~/trafico_urbano && bash lanzar_pc2.sh" C-m

# Ventana PC3
tmux new-window -t $SESSION -n "PC3"
tmux send-keys -t $SESSION:PC3 "ssh -o StrictHostKeyChecking=no estudiante@10.43.100.90" C-m
sleep 1
tmux send-keys -t $SESSION:PC3 "cd ~/trafico_urbano && bash lanzar_pc3.sh" C-m

# Ventana de control
tmux new-window -t $SESSION -n "Control"
tmux send-keys -t $SESSION:Control "echo 'Sesión tmux creada. Usa: tmux attach -t $SESSION'" C-m
tmux send-keys -t $SESSION:Control "echo 'Ctrl+B [número] para cambiar entre ventanas'" C-m
tmux send-keys -t $SESSION:Control "echo 'Ctrl+B D para desconectar'" C-m

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Sesión tmux configurada: $SESSION"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Conectar con: tmux attach -t $SESSION"
echo ""
echo "Navegación en tmux:"
echo "  • Ctrl+B 1 = PC1"
echo "  • Ctrl+B 2 = PC2"
echo "  • Ctrl+B 3 = PC3"
echo "  • Ctrl+B 4 = Control"
echo "  • Ctrl+B D = Desconectar"
echo ""
echo "Ahora te pedirá la contraseña para cada PC."
echo "Ingresalas cuando se te solicite en cada ventana."
