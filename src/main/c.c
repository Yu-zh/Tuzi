#include <stdlib.h>
#include <termios.h>
#include <unistd.h>

void moonbit_hello(void) { write(STDOUT_FILENO, "hello from c", 13); }

struct termios orig_termios;

void disable_raw_mode(void) {
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void enable_raw_mode(void) {
  struct termios raw;

  tcgetattr(STDIN_FILENO, &orig_termios);
  atexit(disable_raw_mode);
  raw = orig_termios;
  raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
  raw.c_oflag &= ~(OPOST);
  raw.c_cflag |= (CS8);
  raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
  tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}

int read_key(char *c) { return read(STDIN_FILENO, c, 1); }