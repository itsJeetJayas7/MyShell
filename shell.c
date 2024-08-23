#include "shell.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

#include "command.h"
#include "single_command.h"

command_t *g_current_command = NULL;
single_command_t *g_current_single_command = NULL;

int yyparse(void);

/*
 *  Prints shell prompt
 */

void print_prompt() {
  if (isatty(0)) { 
    printf("myshell>");
    fflush(stdout);
  }
} /* print_prompt() */

extern void zombie() {
  
  int pid = wait3(0, 0, NULL);
  while(waitpid(-1, NULL, WNOHANG) > 0) {
    if (isatty(0)) {
      printf("%d exited\n", pid);
    }
  }
}

extern void controlC() {
  if (isatty(0)) {
    printf("\n");
  }
  int pid = wait3(0, 0, NULL);
  if (pid == -1) {	  
    print_prompt();
  }
}

/*
 *  This main is simply an entry point for the program which sets up
 *  memory for the rest of the program and the turns control over to
 *  yyparse and never returns
 */

int main() {
  
  struct sigaction sa;
  sa.sa_handler = controlC;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;
  if (sigaction(SIGINT, &sa, NULL)) {
      perror("ctrl-c");
      exit(-1);
    }

  struct sigaction sigA2;
  sigA2.sa_handler = zombie;
  sigemptyset(&sigA2.sa_mask);
  sigA2.sa_flags = SA_RESTART;
  int error =  sigaction(SIGCHLD, &sigA2, NULL);
  if (error) {
    perror("sigaction");
    exit(-1);
  }

	
  g_current_command = (command_t *)malloc(sizeof(command_t));
  g_current_single_command =
        (single_command_t *)malloc(sizeof(single_command_t));

  create_command(g_current_command);
  create_single_command(g_current_single_command);
  

  print_prompt();
  yyparse();

} /* main() */
