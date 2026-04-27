# ARM Thumb Assembly for Embedded Systems

Aprende programación en ensamblador ARM Thumb aplicado a sistemas embebidos (Cortex-M). Incluye lecturas teóricas y laboratorios prácticos ejecutables en macOS (Intel) usando QEMU.

## Requisitos

```bash
brew install arm-none-eabi-gcc qemu
```

## Estructura

```
asm/
├── docs/          # Lecturas teóricas
├── labs/          # Ejercicios de laboratorio
└── common/        # Herramientas compartidas (linker, startup, script)
```

## Contenido

### Lecturas (`docs/`)
1. **01_intro_thumb_embedded.md** - Introducción, registros Cortex-M3, vector table, herramientas
2. **02_data_ops.md** - MOV, LDR, STR, ADD, SUB, CMP y flags
3. **03_control_flow.md** - B, BL, condicionales, loops
4. **04_subroutines_stack.md** - Subrutinas, PUSH/POP, convenciones AAPCS
5. **05_bare_metal_io.md** - I/O mapeado en memoria (UART, GPIO)

### Laboratorios (`labs/`)
| Lab | Tema | Verificación |
|-----|------|--------------|
| 1 | Escribir 'A' en UART0 | Salida serial en QEMU |
| 2 | Sumar 0x1234 + 0x5678 → RAM | Monitor QEMU: `x/1wx 0x20000000` |
| 3 | Loop 0-9 → array en RAM | Monitor QEMU verifica array |
| 4 | Subrutina suma 5+7 | Monitor QEMU verifica R0 |
| 5 | Blinky GPIO (LED parpadeante) | Monitor QEMU verifica pin |

## Uso

### Ejecutar un laboratorio
```bash
./common/run_lab.sh labs/lab1/lab1.s
```

### Depurar con GDB (incluye info DWARF)
```bash
./common/run_lab.sh --debug labs/lab1/lab1.s
```

### Usar Makefile por laboratorio
```bash
cd labs/lab1
make          # Ensambla y vincula
make debug    # Ejecuta con GDB
make clean    # Elimina archivos generados
```

## Notas
- Todos los ejecutables incluyen información de depuración (`-g` flag)
- Los archivos generados (`*.o`, `*.elf`) están en `.gitignore`
- Se emula la placa **lm3s6965evb** (Cortex-M3) vía QEMU
