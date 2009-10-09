#ifndef BASE64_H
#define BASE64_H

/**
 * Base64 decoding.
 * @param enc_ptr Pointer to encoded base64 (with 0 at end of string).
 * @param dec_ptr Decoded content.
 * @param dec_len Decoded length.
 */
void base64_decode(const char *enc_ptr, unsigned char **dec_ptr, int *dec_len);

/**
 * Base64 encoding.
 * @param dec_ptr Pointer to decoded buffer.
 * @param dec_len Decoded buffer length.
 * @param enc_ptr Encoded content (with 0 at end of string).
 */
void base64_encode(const unsigned char *dec_ptr, int dec_len, char **enc_ptr);

#endif
