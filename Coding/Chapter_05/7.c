#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>

int main() {
    pid_t pid = fork();

    if (pid == 0) {
        // Child process
        close(STDOUT_FILENO);  // Close standard output

        printf("Child: You won't see this on the screen.\n");

        // Optionally redirect stdout to a file
        // int fd = open("output.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
        // dup2(fd, STDOUT_FILENO);
        // printf("Now this goes into the file!\n");

        exit(0);
    } else {
        // Parent process
        wait(NULL);
        printf("Parent: Child has finished.\n");
    }

    return 0;
}
