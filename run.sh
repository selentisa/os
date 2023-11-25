#!/bin/bash


gnome-terminal --tab --title="Procedure B" -- bash -c 'echo "Compiling and running Procedure B..."; gcc -o proc_b proc_b.c -pthread && ./proc_b; read -p "Procedure B finished. Press Enter to exit"'


gnome-terminal --tab --title="Procedure A" -- bash -c 'echo "Compiling and running Procedure A..."; gcc -o proc_a proc_a.c -pthread && ./proc_a; read -p "Procedure A finished. Press Enter to exit"'
