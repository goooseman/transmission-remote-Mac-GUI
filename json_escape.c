#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "json_escape.h"

const char *convert_from_escape(const char *json_text) {
	int len = 0;
	int state = 0;
	unsigned short ucs = 0;
	char *result = (char *)malloc(strlen(json_text) + 1);
	memset(result, 0, strlen(json_text) + 1);
	
	for (const char *ptr = json_text; *ptr != 0; ptr ++) {
		switch(state) {
			case 0:
				if (*ptr == '\\')
					state = 1;
				else
					result[len ++] = *ptr;
				break;
				
			case 1:
				state = 0;
				if (*ptr == '"' || *ptr == '\\' || *ptr == '/')
					result[len ++] = *ptr;
				else if (*ptr == 'b')
					result[len ++] = '\b';
				else if (*ptr == 'f')
					result[len ++] = '\f';
				else if (*ptr == 'n')
					result[len ++] = '\n';
				else if (*ptr == 'r')
					result[len ++] = '\r';
				else if (*ptr == 't')
					result[len ++] = '\t';
				else if (*ptr == 'u')
					state = 2;
				break;
				
			case 2:
			case 3:
			case 4:
			case 5:
				if (*ptr >= '0' && *ptr <= '9')
					ucs = (ucs << 4) | (*ptr - '0');
				else if (*ptr >= 'a' && *ptr <= 'f')
					ucs = (ucs << 4) | (*ptr - 'a' + 10);
				else if (*ptr >= 'A' && *ptr <= 'F')
					ucs = (ucs << 4) | (*ptr - 'A' + 10);
				state ++;

				// do ucs to utf8 conversion
				if (state == 6) {
					if (ucs < 0x80)
						result[len ++] = ucs;
					else if (ucs < 0x800) {
						result[len ++] = 0xC0 | ((ucs >> 6) & 0x1F);
						result[len ++] = 0x80 | (ucs & 0x3F);
					} else {
						result[len ++] = 0xE0 | (ucs >> 12);
						result[len ++] = 0x80 | ((ucs >> 6) & 0x3F);
						result[len ++] = 0x80 | (ucs & 0x3F);
					}
					state = 0;
				}
				break;
		}
	}
	return result;
}
