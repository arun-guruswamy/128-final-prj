#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xtime_l.h"
#include "xscugic.h"
#include "xiic.h"
#include "xuartps.h"
#include "xil_cache.h"
#include "sleep.h"

// Custom includes
#include "intc/intc.h"
#include "iic/iic.h"
#include "audio/audio.h"
#include "display_demo.h"

// UART and AXI base config
#define UART_DEVICE_ID XPAR_PS7_UART_1_DEVICE_ID
#define UART_BASEADDR XPAR_PS7_UART_1_BASEADDR
#define AXI_LITE_BASEADDR XPAR_AUDIO_PASSTHROUGH_0_BASEADDR

s32 *baseaddr_p = (s32 *)AXI_LITE_BASEADDR;
XUartPs UartPs;
XUartPs_Config *Config;
static XIic sIic;
static XScuGic sIntc;

// Interrupt vector table
const ivt_t ivt[] = {
    {XPAR_FABRIC_AXI_IIC_0_IIC2INTC_IRPT_INTR, (Xil_ExceptionHandler)XIic_InterruptHandler, &sIic}
};

// Convert string to int
s32 string_to_int32(const char *str) {
    int result = 0;
    s32 result_32b;
    while (*str) {
        if (*str >= '0' && *str <= '9') {
            result = result * 10 + (*str - '0');
        }
        str++;
    }
    result_32b = (s32)result;
    return result_32b;
}

// UART user input
void getUserInput() {
    char userInput[10];
    char char_received = '0';
    s32 input_value = 0;
    s32 input_register_value = 0;
    int i = 0;
    int step = 0;

    while (XUartPs_IsReceiveData(UART_BASEADDR)) {
        XUartPs_ReadReg(UART_BASEADDR, XUARTPS_FIFO_OFFSET);
    }

    xil_printf("Write LEFT audio DDS phase increment to REGISTER 0\n\r");
    xil_printf("Write RIGHT audio DDS phase increment to REGISTER 1\n\r");
    xil_printf("Enter register offset (0 = LEFT, 1 = RIGHT): \n\r");

    while (!XUartPs_IsReceiveData(UART_BASEADDR)) {}

    while (char_received != 'q') {
        if (XUartPs_IsReceiveData(UART_BASEADDR)) {
            char_received = XUartPs_ReadReg(UART_BASEADDR, XUARTPS_FIFO_OFFSET);

            if (char_received == '\r') {
                userInput[i] = '\0';
                xil_printf("\n\r");

                if (step == 0) {
                    input_register_value = string_to_int32(userInput);
                    xil_printf("Register offset entered: %d\n\r", input_register_value);
                    step = 1;
                    xil_printf("Enter DDS phase increment value: \n\r");
                } else if (step == 1) {
                    input_value = string_to_int32(userInput);
                    xil_printf("Value entered: %d\n\r", input_value);

                    *(baseaddr_p + input_register_value) = input_value;
                    xil_printf("Wrote %d to register offset %d\n\r", input_value, input_register_value);

                    step = 0;
                    xil_printf("Enter register offset (0 = LEFT, 1 = RIGHT): \n\r");
                }

                for (int k = 0; k < 10; k++) userInput[k] = '0';
                char_received = '0';
                i = 0;
            } else {
                xil_printf("%c", char_received);
                userInput[i++] = char_received;
            }
        }
    }
    return;
}

// UART init
int configureUart() {
    Config = XUartPs_LookupConfig(UART_DEVICE_ID);
    if (Config == NULL) return XST_FAILURE;

    XUartPs_CfgInitialize(&UartPs, Config, Config->BaseAddress);
    XUartPs_SetBaudRate(&UartPs, 115200);
    xil_printf("UART ready\n\r");
    return 0;
}

// MAIN
int main() {
    int Status;

    // Init interrupts
    Status = fnInitInterruptController(&sIntc);
    if (Status != XST_SUCCESS) {
        xil_printf("Interrupt init failed\n\r");
        return XST_FAILURE;
    }

    // Init I2C
    Status = fnInitIic(&sIic);
    if (Status != XST_SUCCESS) {
        xil_printf("IIC init failed\n\r");
        return XST_FAILURE;
    }

    // Init audio codec
    Status = fnInitAudio();
    if (Status != XST_SUCCESS) {
        xil_printf("Audio codec init failed\n\r");
        return XST_FAILURE;
    }

    // 2 second delay
    XTime tStart, tEnd;
    XTime_GetTime(&tStart);
    do { XTime_GetTime(&tEnd); }
    while ((tEnd - tStart) / (COUNTS_PER_SECOND / 10) < 20);

    fnSetLineInput();

    // Enable interrupt vector table
    fnEnableInterrupts(&sIntc, &ivt[0], sizeof(ivt) / sizeof(ivt[0]));
    xil_printf("Audio system initialized.\n\r");

    // Init UART
    configureUart();

    // Initialize HDMI/display controller
    DemoInitialize();

    xil_printf("\n\r-----------------------------\n\r");
    xil_printf("AXI DDS demo with display ready\n\r");
    xil_printf("Press q to quit DDS entry\n\r");
    xil_printf("-----------------------------\n\r");

    getUserInput(); // start DDS register entry loop

    xil_printf("Exiting...\n\r");
    return 0;
}
