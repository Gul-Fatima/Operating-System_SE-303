#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    int pipefd[2];
    if (pipe(pipefd) == -1) {
        perror("pipe failed");
        exit(1);
    }

    pid_t child1 = fork();
    if (child1 == 0) {
        // First child: runs 'ls -l'
        close(pipefd[0]);             // Close read end
        dup2(pipefd[1], STDOUT_FILENO); // Redirect stdout to pipe
        close(pipefd[1]);

        execlp("ls", "ls", "-l", (char *)NULL);
        perror("exec ls failed");
        exit(1);
    }

    pid_t child2 = fork();
    if (child2 == 0) {
        // Second child: runs 'wc -l'
        close(pipefd[1]);             // Close write end
        dup2(pipefd[0], STDIN_FILENO);  // Redirect stdin from pipe
        close(pipefd[0]);

        execlp("wc", "wc", "-l", (char *)NULL);
        perror("exec wc failed");
        exit(1);
    }

    // Parent process
    close(pipefd[0]);
    close(pipefd[1]);

    waitpid(child1, NULL, 0);
    waitpid(child2, NULL, 0);

    printf("Parent: Both children have finished.\n");

    return 0;
}
