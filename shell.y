
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{

}

%union
{
  char * string;
}

%token <string> WORD PIPE
%token NOTOKEN NEWLINE AMPERSAND STDOUT STDIN APPEND_STDOUT STDERR STDOUT_STDERR APPEND_STDOUT_STDERR

%{
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include "command.h"
#include "single_command.h"
#include "shell.h"
#include <stdlib.h>
#include <dirent.h>
#include <regex.h>

void yyerror(const char * s);
int yylex();

%}

%%

goal:
  entire_command_list
  ;

entire_command_list:
     entire_command_list entire_command {
     	execute_command(g_current_command);
	g_current_command = (command_t *) malloc(sizeof(command_t));
	create_command(g_current_command);
     }
  |  entire_command {
        execute_command(g_current_command);
        g_current_command = (command_t *) malloc(sizeof(command_t));
        create_command(g_current_command);
     }
  ;

entire_command:
     single_command_list io_modifier_list background NEWLINE
  |  NEWLINE    
  ;

single_command_list:
     single_command_list PIPE single_command
  |  single_command
  ;

single_command:
    executable argument_list {
	insert_single_command(g_current_command, g_current_single_command);
	g_current_single_command = NULL;
    }
  ;

argument_list:
     argument_list argument
  |  /* can be empty */
  ;

argument:
     WORD {
	if (strcmp(g_current_single_command->arguments[0], "echo") == 0 && strchr($1, '?')) {
         insert_argument(g_current_single_command, strdup($1));
       }
       else {
         expandWildCardsIfNecessary(strdup($1));
       }
     }
  ;

executable:
     WORD {
	g_current_single_command = (single_command_t *) malloc( sizeof(single_command_t) );
	create_single_command(g_current_single_command);
	insert_argument(g_current_single_command, strdup($1));
     }
  ;

io_modifier_list:
     io_modifier_list io_modifier
  |  /* can be empty */   
  ;

io_modifier:
     STDOUT WORD {
       if(g_current_command->out_file == NULL) {
	g_current_command->out_file = strdup($2);
       } else {
	 printf("Ambiguous output redirect.\n");
         exit(1);
       }
     }
  | STDIN WORD {
	g_current_command->in_file = strdup($2);
     }
  | STDERR WORD {
	g_current_command->err_file = strdup($2);
     }
  | APPEND_STDOUT WORD {
	g_current_command->out_file = strdup($2);
	g_current_command->append_out = 1;
     }
  | STDOUT_STDERR WORD {
	g_current_command->out_file = strdup($2);
	g_current_command->err_file = strdup($2);
     }
  | APPEND_STDOUT_STDERR WORD {
	g_current_command->out_file = strdup($2);
	g_current_command->err_file = strdup($2);
	g_current_command->append_out = 1;
        g_current_command->append_err = 1;
     }
  ;

background:
     AMPERSAND {
	g_current_command->background = 1;
     }
  |
  ;


%%

int maxEntries = 20;
int nEntries = 0;
char ** entries;

int compfunc (const void *file1, const void *file2) {
  const char *_file1 = *(const char **)file1;
  const char *_file2 = *(const char **)file2;
  return strcmp(_file1, _file2);
}

int arraySort(const void* s1,const void* s2) {
  return strcmp(*(char**)s1,*(char**)s2);
}

void expandWildCardsIfNecessary(char * arg) { 
  if (strchr(arg, '*') || strchr(arg, '?')) {
    maxEntries = 20;
    nEntries = 0;
    entries = (char **) malloc (maxEntries * sizeof(char *));
    expandWildCards((char *)"", arg);
    qsort(entries, nEntries, sizeof(char *), compfunc);
    for (int i = 0; i < nEntries; i++) insert_argument(g_current_single_command, entries[i]);
  }
  else {
    insert_argument(g_current_single_command, arg);
  }
  return;
}
int flag = 0;
#define MAXFILENAME 1024
void expandWildCards(char * prefix, char * suffix) {
  if(suffix[0] == '\0') {
    if(nEntries == maxEntries) {
      maxEntries = maxEntries * 2;
      entries = (char **) realloc(entries, sizeof(char *) * maxEntries);
    }
    entries[nEntries] = strdup(prefix);
    nEntries++;
    return;
  }
  char * s = strchr(suffix, '/');
  char component[MAXFILENAME];
  if(s != 0) {
    if(!(s - suffix)) {
      strcpy(component, "");
    } else {
      strncpy(component, suffix, s - suffix);
    }   
    suffix = s + 1;
  } else {
    strcpy(component, suffix);
    suffix = suffix + strlen(suffix);
  }
  char new_prefix[MAXFILENAME];
  if(!strchr(component, '*') && !strchr(component, '?')) {
    if(strlen(prefix) == 1 && prefix[0] == '/') {
      sprintf(new_prefix, "%s%s", prefix, component);
    } else {
      sprintf(new_prefix, "%s/%s", prefix, component);
    }   
    expandWildCards(new_prefix, suffix);
    return;
  }
  char * regex = (char *) malloc(2 * strlen(component) + 3);
  char * arg_pos = component;
  char * regex_pos = regex;
  *regex_pos++ = '^';
  while(*arg_pos) {
    if(*arg_pos == '*') {
      *regex_pos++ = '.';
      *regex_pos++ = '*';
    }
    else if(*arg_pos == '?') {
      *regex_pos++ ='.';
    }
    else if(*regex_pos == '.') {
      *regex_pos++ = '\\';
      *regex_pos++ = '.';
    }
    else {
      *regex_pos++ = *arg_pos;
    }
    arg_pos++;
  }
  *regex_pos++ = '$';
  *regex_pos = '\0';
  regex_t re;
  int status = regcomp(&re, regex, REG_EXTENDED|REG_NOSUB);
  if(status != 0) {
    perror("compile");
    return;
  }
  char * dir_value;
  if(prefix[0] == 0) {
    dir_value = (char*)".";
  }
  else {
    dir_value = prefix;
  }
  DIR * dir = opendir(dir_value);
  if(dir == NULL) {
    if(suffix == NULL) { 
      if(nEntries == maxEntries) {
	maxEntries *= 2;
	entries =(char**)realloc(entries,sizeof(char*)*maxEntries);
      }
      entries[nEntries] = strdup(prefix);
      nEntries += 1;
      flag = 1;
    }
    return;
  }
  struct dirent * ent;
  while((ent = readdir(dir)) != NULL) {
    if (regexec(&re, ent->d_name, 0, 0, 0)) {
    } else {
      if(component[0] != '.' && ent->d_name[0] != '.') {
        if(strlen(prefix) == 0) {
          sprintf(new_prefix, "%s", ent->d_name);
        }
        else {
          if(strlen(prefix) == 1 && prefix[0]=='/') {
            sprintf(new_prefix, "%s%s", prefix, ent->d_name);
          } else {
            sprintf(new_prefix, "%s/%s", prefix, ent->d_name);
          }
        }
        expandWildCards(new_prefix, suffix);
      }
      else if(component[0] == '.' && ent->d_name[0] == '.') {
        if(strlen(prefix) == 0) {
          sprintf(new_prefix, "%s", ent->d_name);
        } else {
          sprintf(new_prefix, "%s/%s", prefix, ent->d_name);
        }
        expandWildCards(new_prefix, suffix);
      }
      else if(component[0] != '.' && ent->d_name[0] != '.') {
        if(strlen(prefix) == 0) {
          sprintf(new_prefix, "%s", ent->d_name);
        }
        else {
          if(strlen(prefix) == 1 && prefix[0]=='/') {
            sprintf(new_prefix, "%s%s", prefix, ent->d_name);
	  } else {
	    sprintf(new_prefix, "%s/%s", prefix, ent->d_name);
	  }
        }
        expandWildCards(new_prefix, suffix);
      }
    }
  }
  closedir(dir);
  regfree(&re);  
}

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  yyparse();
}
#endif
