#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

// Uncomment the exec variant you want to test

int main() {
    pid_t pid = fork();

    if (pid < 0) {
        perror("fork failed");
        exit(1);
    }

    if (pid == 0) {
        // CHILD PROCESS: replace with /bin/ls using one exec variant
        
        // 1. execl() – Full path, list of args
        // execl("/bin/ls", "ls", "-l", (char *)NULL);

        // 2. execle() – Like execl, but with environment
        // char *envp[] = { "MYVAR=hello", NULL };
        // execle("/bin/ls", "ls", "-l", (char *)NULL, envp);

        // 3. execlp() – Searches PATH
        // execlp("ls", "ls", "-l", (char *)NULL);

        // 4. execv() – Full path, array of args
        // char *args[] = { "ls", "-l", NULL };
        // execv("/bin/ls", args);

        // 5. execvp() – Uses PATH, array of args
        // char *args[] = { "ls", "-l", NULL };
        // execvp("ls", args);

        // 6. execvpe() – Like execvp, but with custom environment
        // char *args[] = { "ls", "-l", NULL };
        // char *envp[] = { "MYVAR=hello", NULL };
        // execvpe("ls", args, envp);

        // Default if none selected
        printf("No exec() call was selected.\n");
        exit(1);
    } else {
        // PARENT PROCESS
        wait(NULL); // Wait for the child
        printf("Parent: Child has finished executing ls.\n");
    }

    return 0;
}
