// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdbool.h>
// #include <float.h>
#include <math.h>
#include "demo_system.h"

int main(void) {
  double a = pow(2, 2);
  double b = 3;
  if(a == b) 
    puthex(a);
  else 
    puthex(b);
  return 0;
}
