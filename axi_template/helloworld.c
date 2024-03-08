/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <xil_types.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

int main()
{
    init_platform();
    u32 data = 0;
    u32 data_read = 0;
    u32 err = 0;

    while(1){
        Xil_Out32(0x40000000, data);
        data_read = Xil_In32(0x40000000);

        if (data != data_read)
            err++;
            
        data++;
    }

    cleanup_platform();
    return 0;
}
