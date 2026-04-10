# Gestión Inteligente de Tráfico Urbano
## Introducción a Sistemas Distribuidos — 2026-30

---

## Contenido del proyecto

```
trafico_urbano/
├── config/
│   └── config.json              Configuración global del sistema
├── common/
│   ├── config_loader.py         Carga y utilidades de configuración
│   └── logger.py                Logger estándar para todos los servicios
├── pc1/
│   ├── broker_zmq.py            Broker ZMQ (simple y multihilo)
│   ├── sensor_camara.py         Sensor cámara (EVENTO_LONGITUD_COLA)
│   ├── sensor_espira.py         Sensor espira (EVENTO_CONTEO)
│   └── sensor_gps.py            Sensor GPS (EVENTO_DENSIDAD_TRAFICO)
├── pc2/
│   ├── servicio_analitica.py    Analítica, detección de congestión, control
│   ├── servicio_semaforos.py    Control de estados de semáforos
│   └── base_datos_replica.py    BD réplica (SQLite, backup de PC3)
├── pc3/
│   ├── base_datos_principal.py  BD principal + heartbeat publisher
│   └── servicio_monitoreo.py    CLI de consultas y comandos directos
├── lanzar_pc1.sh                Script de arranque de PC1
├── lanzar_pc2.sh                Script de arranque de PC2
├── lanzar_pc3.sh                Script de arranque de PC3
└── README.md
```

---

## Prerequisitos

- Python 3.9 o superior.
- Librería `pyzmq`:

```bash
pip install pyzmq
```

SQLite3 viene incluido con Python.

---

## Configuración inicial

Editar `config/config.json` con las IPs reales de los tres computadores:

```json
"red": {
    "PC1_IP": "192.168.X.Y",
    "PC2_IP": "192.168.X.Z",
    "PC3_IP": "192.168.X.W"
}
```

Copiar el proyecto completo en los tres computadores en el mismo directorio
(`~/trafico_urbano`). Los scripts usan rutas relativas.

---

## Ejecución del sistema

El sistema se ejecuta en tres computadores. En cada uno se abre una terminal
para lanzar los servicios con su script `lanzar_pcN.sh` y otra terminal
para seguir los logs en tiempo real con `tail -f`. El orden de arranque es
**PC3 → PC2 → PC1** (primero la BD principal, luego la analítica y la
réplica, y al final el broker y los sensores).

### PC3 — BD Principal

```bash
cd ~/trafico_urbano && bash lanzar_pc3.sh
```

Seguir los logs:

```bash
tail -f ~/trafico_urbano/logs/bd_principal.log
```

### PC2 — Analítica, Semáforos y BD Réplica

```bash
cd ~/trafico_urbano && bash lanzar_pc2.sh
```

Seguir los tres logs en paralelo:

```bash
tail -f ~/trafico_urbano/logs/analitica.log \
        ~/trafico_urbano/logs/semaforos.log \
        ~/trafico_urbano/logs/bd_replica.log
```

Para verificar el failover entre PC3 y la réplica:

```bash
tail -f ~/trafico_urbano/logs/analitica.log | grep -E "PC3|réplica|recuperado|responde"
tail -f ~/trafico_urbano/logs/bd_replica.log
```

### PC1 — Broker y Sensores

```bash
cd ~/trafico_urbano && bash lanzar_pc1.sh
```

Seguir los logs del broker y de los sensores de la intersección C5:

```bash
tail -f ~/trafico_urbano/logs/broker.log \
        ~/trafico_urbano/logs/cam_C5.log \
        ~/trafico_urbano/logs/gps_C5.log
```

Para detener los servicios de un PC, presionar `Ctrl+C` en la terminal del
script de lanzamiento; el script termina todos los procesos hijos.

---

## Servicio de monitoreo (PC3)

Al ejecutar `python3 pc3/servicio_monitoreo.py` aparece la CLI interactiva
con las siguientes opciones:

```
1. Estado actual de una intersección
2. Estado de TODO el sistema
3. Historial de tráfico por intersección y período
4. Historial de congestiones
5. Estadísticas generales de la BD
6. Activar paso de ambulancia (ola verde)
7. Forzar cambio de semáforo en intersección
8. Verificar estado del sistema (ping a analítica)
0. Salir
```

---

## Simulación de falla del PC3

Detener la BD principal en PC3 con `Ctrl+C`. El servicio de analítica
detecta la falla mediante timeout de heartbeat (9 segundos) y conmuta a la
BD réplica en PC2. Al restaurar PC3, la analítica reconecta automáticamente.
La transición queda registrada en `analitica.log`.

---

## Arquitectura de puertos

| Puerto | Protocolo | Origen → Destino              | Descripción                     |
|--------|-----------|-------------------------------|---------------------------------|
| 5555   | XSUB      | Sensores → Broker PC1         | Sensores publican eventos       |
| 5556   | XPUB      | Broker PC1 → Analítica PC2    | Broker reenvía a analítica      |
| 5557   | PULL      | Analítica PC2 → Semáforos PC2 | Comandos de control             |
| 5558   | PULL      | Analítica PC2 → BD Réplica PC2| Persistencia réplica            |
| 5559   | PULL      | Analítica PC2 → BD Principal PC3 | Persistencia principal       |
| 5560   | REP       | Monitoreo PC3 → Analítica PC2 | Consultas y comandos            |
| 5561   | PUB       | BD Principal PC3 → Analítica PC2 | Heartbeat                    |

---

## Reglas de tráfico implementadas

| Estado     | Condición                       | Acción semáforo                 |
|------------|----------------------------------|---------------------------------|
| NORMAL     | Q < 5 AND Vp > 35 AND Cv < 10    | Reset (ciclo estándar 15s)      |
| MODERADO   | Intermedio                       | Extender verde +5s              |
| CONGESTIÓN | Q ≥ 10 OR Vp < 15 OR Cv ≥ 20     | Verde 30s (modo CONGESTIÓN)     |
| PRIORIDAD  | Comando manual                   | Ola verde 60s en ruta indicada  |
