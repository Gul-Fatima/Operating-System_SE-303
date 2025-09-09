#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

//  3. Write another program using fork(). The child process should
//  print “hello”; the parentprocessshouldprint“goodbye”. Youshould
//  try to ensure that the child process always prints first; can you do
//  this without calling wait() in the parent?

int main(){
    int rc = fork();
    if ( rc< 0){
        fprintf(stderr, "fork failed");
        exit(1);
    }else if(rc == 0){
        // child process
        printf("hello\n");
    }else{
        // parent process
        sleep(1); // ensure child prints first //By adding sleep(1), we artificially delay the parent, so the child almost always prints first.
        printf("goodbye\n");
    }
    return 0;
}