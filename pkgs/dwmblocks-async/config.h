#ifndef CONFIG_H
#define CONFIG_H

// String used to delimit block outputs in the status.
#define DELIMITER "  "

// Maximum number of Unicode characters that a block can output.
#define MAX_BLOCK_OUTPUT_LENGTH 45

// Control whether blocks are clickable.
#define CLICKABLE_BLOCKS 1

// Control whether a leading delimiter should be prepended to the status.
#define LEADING_DELIMITER 1

// Control whether a trailing delimiter should be appended to the status.
#define TRAILING_DELIMITER 0

// Define blocks for the status feed as X(icon, cmd, interval, signal).
#define BLOCKS(X)             \
    X("", "/home/stefan/.config/suckless/scripts/sb-music", 0, 15)  \
    X("", "sb-cpu-mem", 10, 4)   \
    X("", "sb-hdd", 60, 1) \
    X("", "sb-temp", 20, 3) \
    X("", "sb-forecast", 18000, 5) \
    X("", "sb-lang", 1, 6)     \
    X("", "sb-updates-void", 18000, 7)  \
    X("", "sb-batt", 60, 8)  \
    X("", "sb-brightness", 0, 10)  \
    X("", "sb-screenshot", 0, 12)  \
    X("", "sb-vol", 0, 14) \
    X("", "sb-date", 60, 9) \
    X("", "sb-net-vpn", 1, 13)  \
    X("", "sb-powermenu", 0, 2) 

#endif  // CONFIG_H
