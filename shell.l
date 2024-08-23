
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{
#include <string.h>
#include "y.tab.h"

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

int backgroundPID;
int lastExitCode;
char * expand_env(char * cmd) {	
  char command[4000];
  int index = 0;
  for(int i = 0; i < strlen(cmd) - 1; i++) {
    if(*(cmd + i) == '$' && *(cmd+i+1) == '{') {
      char var[4000];
      int j = 0;
			for(i = i+2; i < strlen(cmd); i++) {	
				if(*(cmd + i) == '}') {
					var[j] = '\0';
					char * varTemp = (char *) malloc(1000 *sizeof(char));
					if (!strcmp(var, "SHELL")) {
						char realname[100];
                				realpath("/proc/self/exe", realname);
                				sprintf(var, "%d", realname);
						varTemp = realname;
					} else if (!strcmp(var, "$")) {
						sprintf(varTemp, "%d", getpid());
					} else if (!strcmp(var, "?")) {
						sprintf(varTemp, "%d", lastExitCode);
					} else if (!strcmp(var, "!")) {
						sprintf(varTemp, "%d", backgroundPID);
                                        } else {
						varTemp = getenv(var);
					}
					if (varTemp != 0) {
						for(int k = 0; k < strlen(varTemp); k++) {
                                                	command[index++] = varTemp[k];
                                                }
					}
					break;
				} else {
					var[j++] = cmd[i];
				}
			}
		} else {
                	command[index++] = cmd[i];
                }
	}
	if(*(cmd + strlen(cmd) - 1) != '}') {
		command[index++] = cmd[strlen(cmd) - 1];
	}
	command[index++] = '\0';
	return strdup(command);
}
%}

%option noyywrap

%%

"|" {
  return PIPE;
}

"&" {
  return AMPERSAND;
}

">" {
  return STDOUT;
}

"<" {
  return STDIN;
}

">>" {
  return APPEND_STDOUT;
}

"2>" {
  return STDERR;
}

">&" {
  return STDOUT_STDERR;
}

">>&" {
  return APPEND_STDOUT_STDERR;
}

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

~[^ \n\t]* {
  char * loc = strdup(yytext);
  char * home = getenv("HOME");

  if (loc[1] == '\0') {
    yylval.string = strdup(home);
  } 
  else {
    char * tore = (char*) malloc(100 * sizeof(char));

    if (loc[1] == '/') {
	    int i = 0;
	    while(home[i] != '\0') {
		    tore[i] = home[i];
		    i++;
	    }
	    int j = i;
	    i = 1;
	    while(loc[i] != '\0') {
		    tore[j] = loc[i];
		    i++;
		    j++;
	    }
	    tore[j] = '\0';
	    //printf("||%s||\n",tore);
    } 
    else {
	    char* temp = "/homes/";
	    int i = 0;
            while(temp[i] != '\0') {
                    tore[i] = temp[i];
                    i++;
            }
	    int j = i;
	    i = 1;
	    while(loc[i] != '\0') {
                    tore[j] = loc[i];
                    i++;
                    j++;
            }
	    tore[j] = '\0';
            //printf("||%s||\n",tore);
    }
    yylval.string = tore;
  }
  return WORD;
}

"source "[^\t\n]* {
  char * loc = yytext+ strlen("source ");
  FILE * inputFile = fopen(loc, "r+");
  if(!inputFile) {
    perror(yytext);
    exit(2);
  }
  fseek(inputFile, 0, SEEK_SET);
  yypush_buffer_state(yy_create_buffer(inputFile, YY_BUF_SIZE));
  yyparse();
  yypop_buffer_state();
  fclose(inputFile);
}

\$\([^\n\$]*\) {
	char * command = strdup(yytext+2);
	for( int i = yyleng-1; i > 0; i--) {
		if(command[i] == ')') {
			command[i] = '\0';
			break;
		}
	}
	int tmpin = dup(0);
	int tmpout = dup(1);
	int fdpipein[2];
	int fdpipeout[2];
	pipe(fdpipein);
	pipe(fdpipeout);
	write(fdpipein[1], command, strlen(command));
	write(fdpipein[1], "\n", 1);
	write(fdpipein[1], "exit", 4);
	write(fdpipein[1], "\n", 1);
	close(fdpipein[1]);
	dup2(fdpipein[0], 0);
	close(fdpipein[0]);
	dup2(fdpipeout[1], 1);
	close(fdpipeout[1]);
	int ret = fork();
	if (ret == 0) {
		execvp("/proc/self/exe", NULL);
		exit(1);
	} else if (ret < 0) {
		perror("fork");
		exit(1);
	}
	dup2(tmpin, 0);
	dup2(tmpout, 1);
	close(tmpin);
	close(tmpout);
	char ch;
	char * buffer = (char *) malloc (1000 * sizeof(char));
	int i = 0;
	while (read(fdpipeout[0], &ch, 1)) {
		if (ch == '\n') buffer[i++] = ' ';
		else buffer[i++] = ch;
	}
	buffer[i] = '\0';
	for (i = strlen(buffer) - 1; i >= 0; i--) {
		unput(buffer[i]);
	}
}


[^ \t\n|><&]*\\[^ \t\n]* {
  char * escape = (char *) malloc(50 * sizeof(char));
  char * temp = yytext;
  int i = 0;
  for(int j = 0; j < yyleng; j++) {
    if (temp[j] == '\\') {
      if(temp[j+1] == '\\') {
	j++;
	escape[i] = '\\';
	i++;
      } else {
	escape[i] = temp[++j];
	i++;
      }
    } else {
      escape[i] = temp[j];
      i++;
    }
  }
  escape[i] = '\0';
  yylval.string = strdup(escape);
  return WORD;
}

["][^\n\"]*["] {
  yylval.string = strdup(yytext + 1);
  if (yylval.string[ yyleng - 2] == '"') {
    yylval.string[yyleng - 2] = 0;
  }
  return WORD;
}


[^ \t\n<>\|\&]+ {
  /* Assume that file names have only alpha chars */
  char * temp = expand_env(yytext);
  yylval.string = strdup(temp);
  return WORD;
}
