#include <stdio.h>
#include <stdlib.h> // exit
#include <sys/wait.h>
#include <unistd.h> // fork

// Writeaprogramthatcallsfork(). Beforecallingfork(),havethe
//  main process access a variable (e.g., x) and set its value to some
// thing (e.g., 100). What value is the variable in the child process?
//  Whathappenstothevariablewhenboththechildandparentchange
//  the value of x?

int main(){
    int x = 100;
    int rc = fork();
    if (rc < 0){
        fprintf(stderr, "fork failed");
        exit(1);
    }else if(rc == 0){
        // child process
        printf("child: x = %d\n", x);
        x = 200;
        printf("child: changed x to %d\n", x);
    }else{
        //parent process
        int wc = wait(NULL);
        printf("parent: x = %d\n", x);  
        x = 300;
        printf("parent: changed x to %d\n", x);
    }
    return 0;
}