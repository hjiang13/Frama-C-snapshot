/* Generated by Frama-C */
#include "stdio.h"
#include "stdlib.h"
int main(void)
{
  int __retres;
  __e_acsl_memory_init((int *)0,(char ***)0,(size_t)8);
  int x = 0;
  int y = 1;
  /*@ assert x < y; */
  __e_acsl_assert(x < y,(char *)"Assertion",(char *)"main",(char *)"x < y",7);
  /*@ assert y > x; */
  __e_acsl_assert(y > x,(char *)"Assertion",(char *)"main",(char *)"y > x",8);
  /*@ assert x ≤ 0; */
  __e_acsl_assert(x <= 0,(char *)"Assertion",(char *)"main",(char *)"x <= 0",
                  9);
  /*@ assert y ≥ 1; */
  __e_acsl_assert(y >= 1,(char *)"Assertion",(char *)"main",(char *)"y >= 1",
                  10);
  char *s = (char *)"toto";
  /*@ assert s ≡ s; */
  __e_acsl_assert(s == s,(char *)"Assertion",(char *)"main",(char *)"s == s",
                  12);
  /*@ assert 5 < 18; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"5 < 18",15);
  /*@ assert 32 > 3; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"32 > 3",16);
  /*@ assert 12 ≤ 13; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"12 <= 13",17);
  /*@ assert 123 ≥ 12; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"123 >= 12",
                  18);
  /*@ assert 0xff ≡ 0xff; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",
                  (char *)"0xff == 0xff",19);
  /*@ assert 1 ≢ 2; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"1 != 2",20);
  /*@ assert -5 < 18; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"-5 < 18",22);
  /*@ assert 32 > -3; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"32 > -3",23);
  /*@ assert -12 ≤ 13; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"-12 <= 13",
                  24);
  /*@ assert 123 ≥ -12; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"123 >= -12",
                  25);
  /*@ assert -0xff ≡ -0xff; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",
                  (char *)"-0xff == -0xff",26);
  /*@ assert 1 ≢ -2; */
  __e_acsl_assert(1,(char *)"Assertion",(char *)"main",(char *)"1 != -2",27);
  __retres = 0;
  return __retres;
}


