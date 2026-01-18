/**************************************************************
 * FILE: dotprod_posix.c
 * DESCRIPTION:
 *   Multithreaded dot product using POSIX threads (Pthreads).
 *   Each thread computes a part of the sum. Uses mutex for synchronization.
 **************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <time.h>

#define VECLEN 1000000
#define NUM_THREADS 4

// Shared structure
typedef struct {
    double *a;
    double *b;
    double sum;
    int veclen;
} DOTDATA;

DOTDATA dotstr;
pthread_t threads[NUM_THREADS];
pthread_mutex_t mutexsum;

// Structure for thread arguments
typedef struct {
    int thread_id;
    int start;
    int end;
} ThreadData;

// Thread function
void *dotprod(void *arg) {
    ThreadData *data = (ThreadData *)arg;
    double *x = dotstr.a;
    double *y = dotstr.b;
    double partial_sum = 0.0;

    // Compute partial dot product
    for (int i = data->start; i < data->end; i++) {
        partial_sum += x[i] * y[i];
    }

    // Lock before updating global sum
   pthread_mutex_lock(&mutexsum);
    dotstr.sum += partial_sum;
   pthread_mutex_unlock(&mutexsum);
//
    printf("Thread %d finished: partial sum = %f\n", data->thread_id, partial_sum);
//    printf("Thread %d finished: total sum = %f\n", data->thread_id, dotstr.sum);
    pthread_exit(NULL);
}

// Main program
int main() {
    double *a, *b;
    ThreadData thread_data[NUM_THREADS];
    int len = VECLEN;
    int chunk = len / NUM_THREADS;

    pthread_mutex_init(&mutexsum, NULL);

    // Allocate and initialize arrays
    a = (double *)malloc(len * sizeof(double));
    b = (double *)malloc(len * sizeof(double));
    for (int i = 0; i < len; i++) {
        a[i] = 1.0;
        b[i] = 1.0;
    }

    dotstr.a = a;
    dotstr.b = b;
    dotstr.veclen = len;
    dotstr.sum = 0.0;

    clock_t start = clock();

    // Create threads
    for (int i = 0; i < NUM_THREADS; i++) {
        thread_data[i].thread_id = i;
        thread_data[i].start = i * chunk;
        thread_data[i].end = (i == NUM_THREADS - 1) ? len : (i + 1) * chunk;

        pthread_create(&threads[i], NULL, dotprod, &thread_data[i]);
    }

    // Wait for all threads
    for (int i = 0; i < NUM_THREADS; i++) {
        pthread_join(threads[i], NULL);
    }

    clock_t end = clock();
    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;

    printf("\nMulti-threaded Execution Finished.\n");
    printf("Sum = %f\n", dotstr.sum);
    printf("Execution Time: %f seconds\n", time_spent);

    pthread_mutex_destroy(&mutexsum);
    free(a);
    free(b);

    return 0;
}
