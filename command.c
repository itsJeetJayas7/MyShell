/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 * DO NOT PUT THIS PROJECT IN A PUBLIC REPOSITORY LIKE GIT. IF YOU WANT
 * TO MAKE IT PUBLICALLY AVAILABLE YOU NEED TO REMOVE ANY SKELETON CODE
 * AND REWRITE YOUR PROJECT SO IT IMPLEMENTS FUNCTIONALITY DIFFERENT THAN
 * WHAT IS SPECIFIED IN THE HANDOUT. WE OFTEN REUSE PART OF THE PROJECTS FROM
 * SEMESTER TO SEMESTER AND PUTTING YOUR CODE IN A PUBLIC REPOSITORY
 * MAY FACILITATE ACADEMIC DISHONESTY.
 */

#include "command.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include "shell.h"

extern char **environ;
extern int lastExitCode;
extern int backgroundPID;

/*
 *  Initialize a command_t
 */

void create_command(command_t *command) {
  command->single_commands = NULL;

  command->out_file = NULL;
  command->in_file = NULL;
  command->err_file = NULL;

  command->append_out = false;
  command->append_err = false;
  command->background = false;

  command->num_single_commands = 0;
} /* create_command() */

/*
 *  Insert a single command into the list of single commands in a command_t
 */

void insert_single_command(command_t *command, single_command_t *simp) {
  if (simp == NULL) {
    return;
  }

  command->num_single_commands++;
  int new_size = command->num_single_commands * sizeof(single_command_t *);
  command->single_commands = (single_command_t **)
                              realloc(command->single_commands,
                                      new_size);
  command->single_commands[command->num_single_commands - 1] = simp;
} /* insert_single_command() */

/*
 *  Free a command and its contents
 */

void free_command(command_t *command) {
  for (int i = 0; i < command->num_single_commands; i++) {
    free_single_command(command->single_commands[i]);
  }

  if (command->out_file) {
    free(command->out_file);
    command->out_file = NULL;
  }

  if (command->in_file) {
    free(command->in_file);
    command->in_file = NULL;
  }

  if (command->err_file) {
    free(command->err_file);
    command->err_file = NULL;
  }

  command->append_out = false;
  command->append_err = false;
  command->background = false;

  free(command);
} /* free_command() */

/*
 *  Print the contents of the command in a pretty way
 */

void print_command(command_t *command) {
  printf("\n\n");
  printf("              COMMAND TABLE                \n");
  printf("\n");
  printf("  #   single Commands\n");
  printf("  --- ----------------------------------------------------------\n");

  // iterate over the single commands and print them nicely
  for (int i = 0; i < command->num_single_commands; i++) {
    printf("  %-3d ", i );
    print_single_command(command->single_commands[i]);
  }

  printf( "\n\n" );
  printf( "  Output       Input        Error        Background\n" );
  printf( "  ------------ ------------ ------------ ------------\n" );
  printf( "  %-12s %-12s %-12s %-12s\n",
            command->out_file?command->out_file:"default",
            command->in_file?command->in_file:"default",
            command->err_file?command->err_file:"default",
            command->background?"YES":"NO");
  printf( "\n\n" );
} /* print_command() */

/*
 *  Execute a command
 */

void execute_command(command_t *command) {
  // Don't do anything if there are no single commands
  if (command->single_commands == NULL) {
    print_prompt();
    return;
  }
  if (!strcmp(command->single_commands[0]->arguments[0], "exit")) {
	  exit(1);
  }
  // Print contents of Command data structure
  
  if(isatty(0)) {
    //print_command(command);
  }
  // Add execution here
  // For every single command fork a new process
  // Setup i/o redirection
  // and call exec
  // I can make a change?
  
  int tmpin = dup(0);
  int tmpout = dup(1);
  
  //Directing the input
  int fdin;
  if (command->in_file != NULL) {
        fdin = open(command->in_file, O_RDONLY);
  } else {
        fdin = dup(tmpin);
  }
  
  //Directing the err
  int fderr;
  int tmperr = dup(2);
  if (command->err_file != NULL) {
    if (command->append_err) { 
      fderr = open(command->err_file, O_WRONLY | O_APPEND | O_CREAT, 0600);
    } else {
      fderr = open(command->err_file, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    }
  } else {
    fderr = dup(tmperr);
  }
  dup2(fderr, 2);
  close(fderr);

  int ret;
  int fdout;

  for (int i = 0; i < command->num_single_commands; i++) {
  	if (!strcmp(command->single_commands[i]->arguments[0], "setenv")) {
		setenv(command->single_commands[i]->arguments[1], command->single_commands[i]->arguments[2], 1);
		free_command(command);
		print_prompt();
		return;
	}
	if (!strcmp(command->single_commands[i]->arguments[0],"unsetenv")) {
		unsetenv(command->single_commands[i]->arguments[1]);
		free_command(command);
		print_prompt();
		return;
	}
	if (!strcmp(command->single_commands[i]->arguments[0], "cd")) {
		int err;
		if (command->single_commands[i]->num_args == 1) {
			err = chdir(getenv("HOME"));
		} else {
			err = chdir(command->single_commands[i]->arguments[1]);
		}
		if (err < 0) {
			char * errorText = (char *) malloc (1024*sizeof(char));
			sprintf(errorText, "cd: can't cd to %s", command->single_commands[i]->arguments[1]); 
			perror(errorText);
			free(errorText);
			lastExitCode = 1;
		}
		free_command(command);
		print_prompt();
		return;
	}
  }

  for (int i = 0; i < command->num_single_commands; i++) {
    command->single_commands[i]->arguments[command->single_commands[i]->num_args] = NULL;
    dup2(fdin, 0);
    close(fdin);
    if (i == command->num_single_commands - 1) {
      if (command->out_file != NULL) {
        if (command->append_out) {
          fdout = open(command->out_file, O_WRONLY | O_APPEND | O_CREAT, 0600);
        } else {
          fdout = open(command->out_file, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        }
      } else {
        fdout = dup(tmpout);
      }
    } else {
          int fdpipe[2];
          pipe(fdpipe);
          fdout = fdpipe[1];
          fdin = fdpipe[0];
    }
    dup2(fdout, 1);
    close(fdout);
    ret = fork();

    if (ret < 0) {
      perror("fork");
      return;
    }
    if (ret == 0) {
      if (!strcmp(command->single_commands[i]->arguments[0], "printenv")) {
	char **p = environ;
  	while (*p != NULL) {
  	  printf("%s\n", *p++);
  	}
	exit(0);
      } else if (!strcmp(command->single_commands[i]->arguments[0], "source")) {
	FILE * fs = fopen(command->single_commands[i]->arguments[1], "r");
	char cmdLine[2048];
	fgets(cmdLine, 2047, fs);
       	fclose(fs);

	int tmpin = dup(0);
	int tmpout = dup(1);
	int fdpipein[2];
	int fdpipeout[2];
	pipe(fdpipein);
	pipe(fdpipeout);
				
	write(fdpipein[1], cmdLine, strlen(cmdLine));
	write(fdpipein[1], "\n", 1);
	close(fdpipein[1]);
	dup2(fdpipein[0], 0);
	close(fdpipein[0]);
	dup2(fdpipeout[1], 1);
	close(fdpipeout[1]);
	int ret = fork();
	if (ret == 0) {
		//execvp("/proc/self/exe", NULL); //Imp
		_exit(1);
	} else if (ret < 0) {
		perror("fork");
		exit(1);
	}

	dup2(tmpin, 0);
	dup2(tmpout, 1);
	close(tmpin);
	close(tmpout);

	char ch;
	char * buffer = (char *) malloc (50*sizeof(char));
	int i = 0;

	while (read(fdpipeout[0], &ch, 1)) {
		if (ch != '\n') {
			buffer[i++] = ch;
		}
	}

	buffer[i] = '\0';
	printf("%s\n",buffer);
      } else {	      
      	execvp(command->single_commands[i]->arguments[0], command->single_commands[i]->arguments);
      	perror("execvp");
      	exit(1);
      }
    }
  }
  dup2(tmpin, 0);
  dup2(tmpout, 1);
  dup2(tmperr, 2);
  close(tmpin);
  close(tmpout);
  close(tmperr);
  if (!(command->background)) {
    int temp;
    waitpid(ret, &temp, 0);
    lastExitCode = WEXITSTATUS(temp);
  }
  else {
    backgroundPID = ret;
  }

  
  // Clear to prepare for next command
  free_command(command);

  // Print new prompt
  print_prompt();
} /* execute_command() */
