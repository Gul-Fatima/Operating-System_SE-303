/**************************************************************************
 ****
 * FILE: dotprod_serial.c
 * DESCRIPTION: A simple serial program to compute a vector dot product.
 ***************************************************************************
 ***/

#include <stdio.h>
#include <stdlib.h>
#include <time.h> // For measuring time

// This structure holds all data needed for the calculation.
typedef struct {
    double *a;
    double *b;
    double sum;  
    int veclen;  
} DOTDATA;

#define VECLEN 1000000 // Using a larger vector for more meaningful timing

DOTDATA dotstr;  

// The function that performs the dot product calculation.
void dotprod() {
    int i;  
    double mysum, *x, *y;
    x = dotstr.a;
    y = dotstr.b;

    // Perform the dot product
    mysum = 0;
    for (i = 0; i < dotstr.veclen; i++) {
        mysum += (x[i] * y[i]);
    }
    dotstr.sum = mysum;
}

// The main program initializes data, calls the function, and prints the result.
int main (int argc, char *argv[]) {
    int i, len;
    double *a, *b;

    // Assign storage and initialize values
    len = VECLEN;
    a = (double*) malloc(len * sizeof(double));
    b = (double*) malloc(len * sizeof(double));

    for (i = 0; i < len; i++) {
        a[i] = 1.0;
        b[i] = a[i];
    }

    dotstr.veclen = len;  
    dotstr.a = a;  
    dotstr.b = b;  
    dotstr.sum = 0;

    // --- Time Measurement Start ---
    clock_t start = clock();

    // Perform the dot product
    dotprod();

    // --- Time Measurement End ---
    clock_t end = clock();
    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;

    // Print result and release storage  
    printf("Serial Execution Finished.\n");
    printf("Sum =  %f \n", dotstr.sum);
    printf("Execution Time: %f seconds\n", time_spent);

    free(a);
    free(b);
    return 0;
}

