/* Generated by Frama-C */
#include "stdio.h"
#include "stdlib.h"
char *__gen_e_acsl_literal_string_2;
char *__gen_e_acsl_literal_string;
void __e_acsl_globals_init(void)
{
  __gen_e_acsl_literal_string_2 = "g";
  __e_acsl_store_block((void *)__gen_e_acsl_literal_string_2,sizeof("g"));
  __e_acsl_full_init((void *)__gen_e_acsl_literal_string_2);
  __e_acsl_mark_readonly((void *)__gen_e_acsl_literal_string_2);
  __gen_e_acsl_literal_string = "f";
  __e_acsl_store_block((void *)__gen_e_acsl_literal_string,sizeof("f"));
  __e_acsl_full_init((void *)__gen_e_acsl_literal_string);
  __e_acsl_mark_readonly((void *)__gen_e_acsl_literal_string);
  return;
}

int main(void)
{
  int __retres;
  char *g;
  char *q;
  __e_acsl_memory_init((int *)0,(char ***)0,(size_t)8);
  __e_acsl_globals_init();
  __e_acsl_store_block((void *)(& q),(size_t)8);
  __e_acsl_store_block((void *)(& g),(size_t)8);
  char *f = (char *)__gen_e_acsl_literal_string;
  __e_acsl_store_block((void *)(& f),(size_t)8);
  __e_acsl_full_init((void *)(& f));
  __e_acsl_temporal_store_nblock((void *)(& f),
                                 (void *)__gen_e_acsl_literal_string);
  /*@ assert \valid_read(f) ∧ ¬\valid(f); */
  {
    int __gen_e_acsl_initialized;
    int __gen_e_acsl_and;
    int __gen_e_acsl_and_3;
    __gen_e_acsl_initialized = __e_acsl_initialized((void *)(& f),
                                                    sizeof(char *));
    if (__gen_e_acsl_initialized) {
      int __gen_e_acsl_valid_read;
      __gen_e_acsl_valid_read = __e_acsl_valid_read((void *)f,sizeof(char),
                                                    (void *)f,(void *)(& f));
      __gen_e_acsl_and = __gen_e_acsl_valid_read;
    }
    else __gen_e_acsl_and = 0;
    if (__gen_e_acsl_and) {
      int __gen_e_acsl_initialized_2;
      int __gen_e_acsl_and_2;
      __gen_e_acsl_initialized_2 = __e_acsl_initialized((void *)(& f),
                                                        sizeof(char *));
      if (__gen_e_acsl_initialized_2) {
        int __gen_e_acsl_valid;
        __gen_e_acsl_valid = __e_acsl_valid((void *)f,sizeof(char),(void *)f,
                                            (void *)(& f));
        __gen_e_acsl_and_2 = __gen_e_acsl_valid;
      }
      else __gen_e_acsl_and_2 = 0;
      __gen_e_acsl_and_3 = ! __gen_e_acsl_and_2;
    }
    else __gen_e_acsl_and_3 = 0;
    __e_acsl_assert(__gen_e_acsl_and_3,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid_read(f) && !\\valid(f)",9);
  }
  __e_acsl_temporal_store_nblock((void *)(& g),
                                 (void *)__gen_e_acsl_literal_string_2);
  __e_acsl_full_init((void *)(& g));
  g = (char *)__gen_e_acsl_literal_string_2;
  /*@ assert \valid_read(g) ∧ ¬\valid(g); */
  {
    int __gen_e_acsl_initialized_3;
    int __gen_e_acsl_and_4;
    int __gen_e_acsl_and_6;
    __gen_e_acsl_initialized_3 = __e_acsl_initialized((void *)(& g),
                                                      sizeof(char *));
    if (__gen_e_acsl_initialized_3) {
      int __gen_e_acsl_valid_read_2;
      __gen_e_acsl_valid_read_2 = __e_acsl_valid_read((void *)g,sizeof(char),
                                                      (void *)g,
                                                      (void *)(& g));
      __gen_e_acsl_and_4 = __gen_e_acsl_valid_read_2;
    }
    else __gen_e_acsl_and_4 = 0;
    if (__gen_e_acsl_and_4) {
      int __gen_e_acsl_initialized_4;
      int __gen_e_acsl_and_5;
      __gen_e_acsl_initialized_4 = __e_acsl_initialized((void *)(& g),
                                                        sizeof(char *));
      if (__gen_e_acsl_initialized_4) {
        int __gen_e_acsl_valid_2;
        __gen_e_acsl_valid_2 = __e_acsl_valid((void *)g,sizeof(char),
                                              (void *)g,(void *)(& g));
        __gen_e_acsl_and_5 = __gen_e_acsl_valid_2;
      }
      else __gen_e_acsl_and_5 = 0;
      __gen_e_acsl_and_6 = ! __gen_e_acsl_and_5;
    }
    else __gen_e_acsl_and_6 = 0;
    __e_acsl_assert(__gen_e_acsl_and_6,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid_read(g) && !\\valid(g)",12);
  }
  char *p = f;
  __e_acsl_store_block((void *)(& p),(size_t)8);
  __e_acsl_full_init((void *)(& p));
  __e_acsl_temporal_store_nreferent((void *)(& p),(void *)(& f));
  /*@ assert \valid_read(p) ∧ ¬\valid(p); */
  {
    int __gen_e_acsl_initialized_5;
    int __gen_e_acsl_and_7;
    int __gen_e_acsl_and_9;
    __gen_e_acsl_initialized_5 = __e_acsl_initialized((void *)(& p),
                                                      sizeof(char *));
    if (__gen_e_acsl_initialized_5) {
      int __gen_e_acsl_valid_read_3;
      __gen_e_acsl_valid_read_3 = __e_acsl_valid_read((void *)p,sizeof(char),
                                                      (void *)p,
                                                      (void *)(& p));
      __gen_e_acsl_and_7 = __gen_e_acsl_valid_read_3;
    }
    else __gen_e_acsl_and_7 = 0;
    if (__gen_e_acsl_and_7) {
      int __gen_e_acsl_initialized_6;
      int __gen_e_acsl_and_8;
      __gen_e_acsl_initialized_6 = __e_acsl_initialized((void *)(& p),
                                                        sizeof(char *));
      if (__gen_e_acsl_initialized_6) {
        int __gen_e_acsl_valid_3;
        __gen_e_acsl_valid_3 = __e_acsl_valid((void *)p,sizeof(char),
                                              (void *)p,(void *)(& p));
        __gen_e_acsl_and_8 = __gen_e_acsl_valid_3;
      }
      else __gen_e_acsl_and_8 = 0;
      __gen_e_acsl_and_9 = ! __gen_e_acsl_and_8;
    }
    else __gen_e_acsl_and_9 = 0;
    __e_acsl_assert(__gen_e_acsl_and_9,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid_read(p) && !\\valid(p)",15);
  }
  __e_acsl_temporal_store_nreferent((void *)(& q),(void *)(& f));
  __e_acsl_full_init((void *)(& q));
  q = f;
  /*@ assert \valid_read(q) ∧ ¬\valid(q); */
  {
    int __gen_e_acsl_initialized_7;
    int __gen_e_acsl_and_10;
    int __gen_e_acsl_and_12;
    __gen_e_acsl_initialized_7 = __e_acsl_initialized((void *)(& q),
                                                      sizeof(char *));
    if (__gen_e_acsl_initialized_7) {
      int __gen_e_acsl_valid_read_4;
      __gen_e_acsl_valid_read_4 = __e_acsl_valid_read((void *)q,sizeof(char),
                                                      (void *)q,
                                                      (void *)(& q));
      __gen_e_acsl_and_10 = __gen_e_acsl_valid_read_4;
    }
    else __gen_e_acsl_and_10 = 0;
    if (__gen_e_acsl_and_10) {
      int __gen_e_acsl_initialized_8;
      int __gen_e_acsl_and_11;
      __gen_e_acsl_initialized_8 = __e_acsl_initialized((void *)(& q),
                                                        sizeof(char *));
      if (__gen_e_acsl_initialized_8) {
        int __gen_e_acsl_valid_4;
        __gen_e_acsl_valid_4 = __e_acsl_valid((void *)q,sizeof(char),
                                              (void *)q,(void *)(& q));
        __gen_e_acsl_and_11 = __gen_e_acsl_valid_4;
      }
      else __gen_e_acsl_and_11 = 0;
      __gen_e_acsl_and_12 = ! __gen_e_acsl_and_11;
    }
    else __gen_e_acsl_and_12 = 0;
    __e_acsl_assert(__gen_e_acsl_and_12,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid_read(q) && !\\valid(q)",18);
  }
  __retres = 0;
  __e_acsl_delete_block((void *)(& q));
  __e_acsl_delete_block((void *)(& p));
  __e_acsl_delete_block((void *)(& g));
  __e_acsl_delete_block((void *)(& f));
  __e_acsl_memory_clean();
  return __retres;
}


