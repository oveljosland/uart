# UART

## Programming the flash
Follow these steps to make the design persistent on the FPGA.
- Compile the design.
- Open the Quartus Programmer.
- Open the "Change File" menu.
- Go to the `output_files` directory of your project.
- Select the programmer object file `uart.pof`.
- Check the "Program/Configure" box for the object file.
- Start the programmer.