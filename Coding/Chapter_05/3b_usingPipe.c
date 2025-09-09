#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    int fd[2];  //creates a pipe wqith 2 ends( 0 for read, 1 for write)
    pipe(fd);

    int rc = fork();
    if (rc < 0) {
        perror("fork failed");
        exit(1);
    } else if (rc == 0) {
        // Child process
        printf("hello\n");
        close(fd[0]); // close read end, not required
        write(fd[1], "done", 4); // signal parent : tells to write into pipe "done = 4 bytes"
        close(fd[1]); //close end after writing
    } else {
        // Parent process
        char buf[4];
        close(fd[1]); // close write end, not required
        read(fd[0], buf, 4); // block until child writes, the done printed in poipe unblocks read for paarent
        close(fd[0]); //close end after reading
        printf("goodbye\n");
    }
    return 0;
    
}
