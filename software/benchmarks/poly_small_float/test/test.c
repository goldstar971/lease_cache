/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* syrk.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>



#include "riscv.h"

float test_nested(float k,float n){
	float r;
	r=rand()/7.0;
		 n=k;
 	if(r==n){
 		k=(float)((int)(k*k)>>2);
 	}
	 else{
 		k=r*n;
	}
	return k;
}

float mul_div(float n,int multican, int divsor){
	float k;
	k=n*multican;
	k=k/divsor;
	k=test_nested(k,n);
	return k;
}



int main(int argc, char** argv)
{
	float k,n=12.3;
	k=mul_div(n,13,37);
k=sqrtf(k);
benchmark_timer_stop();
  
  
 

  return 0;
}
