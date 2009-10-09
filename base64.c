#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "base64.h"

static const char cb64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char cd64[] = "|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq";

void base64_blkdec(unsigned char in[4], unsigned char out[3]) {
	out[0] = (unsigned char) (in[0] << 2 | in[1] >> 4);
	out[1] = (unsigned char) (in[1] << 4 | in[2] >> 2);
	out[2] = (unsigned char) (((in[2] << 6) & 0xc0) | in[3]);
}

void base64_decode(const char *enc_ptr, unsigned char **dec_ptr, int *dec_len) {
	unsigned char in[4], out[3], v;
	int enc_len = strlen(enc_ptr);
	int i, len;

	int dec_max = (enc_len + 4) * 3 / 4;
	(*dec_ptr) = (unsigned char *) malloc(dec_max);
	(*dec_len) = 0;
	if ((*dec_ptr) == 0)
		return;

	while (*enc_ptr != 0) {
		for (len = 0, i = 0; i < 4 && *enc_ptr != 0; i++) {
			v = 0;
			while (*enc_ptr != 0 && v == 0) {
				v = (unsigned char) (*enc_ptr++);
				v = (unsigned char) ((v < 43 || v > 122) ? 0 : cd64[v - 43]);
				if (v)
					v = (unsigned char) ((v == '$') ? 0 : v - 61);
			}
			if (*enc_ptr != 0) {
				len++;
				if (v)
					in[i] = (unsigned char) (v - 1);
			} else
				in[i] = 0;
		}
		if (len) {
			base64_blkdec(in, out);
			for (i = 0; i < len - 1; i++)
				(*dec_ptr)[(*dec_len)++] = out[i];
		}
	}
}

void base64_blkenc(unsigned char in[3], unsigned char out[4], int len) {
	out[0] = cb64[in[0] >> 2];
    out[1] = cb64[((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4)];
    out[2] = (unsigned char) (len > 1 ? cb64[((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6)] : '=');
	out[3] = (unsigned char) (len > 2 ? cb64[in[2] & 0x3f] : '=');
}

void base64_encode(const unsigned char *dec_ptr, int dec_len, char **enc_ptr) {
	unsigned char in[3], out[4];
	int i, len, enc_len = 0;
	
	int enc_max = (dec_len + 3) * 4 / 3 + 1;
	(*enc_ptr) = (char *) malloc(enc_max);
	if ((*enc_ptr) == 0)
		return;
	else
		(*enc_ptr)[enc_len] = 0;
	
	while (dec_len > 0) {
		len = 0;
		for (i = 0; i < 3; i++) {
            if (dec_len > 0) {
				in[i] = (unsigned char) (*(dec_ptr ++));
				dec_len --;
                len ++;
            } else {
                in[i] = 0;
            }
		}
		if (len) {
            base64_blkenc(in, out, len);
            for (i = 0; i < 4; i++) {
				(*enc_ptr)[enc_len ++] = out[i];
				(*enc_ptr)[enc_len] = 0;
            }
        }
	}
}
