#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

int main() {
    // Open file using open() system call
    int fd = open("test.txt", O_CREAT | O_WRONLY | O_TRUNC, 0644);
    if (fd < 0) {
        perror("open failed");
        exit(1);
    }

    int rc = fork();
    if (rc < 0) {
        perror("fork failed");
        exit(1);
    } 
    else if (rc == 0) {
        // Child process
        for (int i = 0; i < 5; i++) {
            write(fd, "Child writing\n", 14);
            sleep(1);
        }
    } 
    else {
        // Parent process
        for (int i = 0; i < 5; i++) {
            write(fd, "Parent writing\n", 15);
            sleep(1);
        }
        wait(NULL); // wait for child to finish
    }

    close(fd);
    return 0;
}
