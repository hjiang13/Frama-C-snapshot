/* Generated by Frama-C */
#include "errno.h"
#include "stdio.h"
#include "stdlib.h"
void __e_acsl_globals_init(void)
{
  __e_acsl_store_block((void *)(& errno),(size_t)4);
  __e_acsl_full_init((void *)(& errno));
  return;
}

int main(int argc, char const **argv)
{
  int __retres;
  __e_acsl_memory_init(& argc,(char ***)(& argv),(size_t)8);
  __e_acsl_globals_init();
  int *p = & errno;
  __e_acsl_store_block((void *)(& p),(size_t)8);
  __e_acsl_full_init((void *)(& p));
  /*@ assert \valid(p); */
  {
    int __gen_e_acsl_initialized;
    int __gen_e_acsl_and;
    __gen_e_acsl_initialized = __e_acsl_initialized((void *)(& p),
                                                    sizeof(int *));
    if (__gen_e_acsl_initialized) {
      int __gen_e_acsl_valid;
      __gen_e_acsl_valid = __e_acsl_valid((void *)p,sizeof(int),(void *)p,
                                          (void *)(& p));
      __gen_e_acsl_and = __gen_e_acsl_valid;
    }
    else __gen_e_acsl_and = 0;
    __e_acsl_assert(__gen_e_acsl_and,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(p)",11);
  }
  __retres = 0;
  __e_acsl_delete_block((void *)(& errno));
  __e_acsl_delete_block((void *)(& p));
  __e_acsl_memory_clean();
  return __retres;
}


