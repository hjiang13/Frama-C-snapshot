/* Generated by Frama-C */
#include "stdio.h"
#include "stdlib.h"
char *__gen_e_acsl_literal_string;
void f(void const *s, int c, unsigned long n)
{
  __e_acsl_store_block((void *)(& s),(size_t)4);
  unsigned char const *p = (unsigned char const *)s;
  __e_acsl_store_block((void *)(& p),(size_t)4);
  __e_acsl_full_init((void *)(& p));
  /*@ assert p - (unsigned char const *)s ≡ n - n; */
  __e_acsl_assert(p - (unsigned char const *)s == n - (long long)n,
                  (char *)"Assertion",(char *)"f",
                  (char *)"p - (unsigned char const *)s == n - n",16);
  /*@ assert p - (unsigned char const *)s ≡ 0; */
  __e_acsl_assert(p - (unsigned char const *)s == 0U,(char *)"Assertion",
                  (char *)"f",(char *)"p - (unsigned char const *)s == 0",17);
  __e_acsl_delete_block((void *)(& s));
  __e_acsl_delete_block((void *)(& p));
  return;
}

void __e_acsl_globals_init(void)
{
  __gen_e_acsl_literal_string = "1234567890";
  __e_acsl_store_block((void *)__gen_e_acsl_literal_string,
                       sizeof("1234567890"));
  __e_acsl_full_init((void *)__gen_e_acsl_literal_string);
  __e_acsl_mark_readonly((void *)__gen_e_acsl_literal_string);
  return;
}

int main(void)
{
  int __retres;
  __e_acsl_memory_init((int *)0,(char ***)0,(size_t)4);
  __e_acsl_globals_init();
  char const *s = __gen_e_acsl_literal_string;
  __e_acsl_store_block((void *)(& s),(size_t)4);
  __e_acsl_full_init((void *)(& s));
  f((void const *)s,'0',(unsigned long)11);
  __retres = 0;
  __e_acsl_delete_block((void *)(& s));
  __e_acsl_memory_clean();
  return __retres;
}


