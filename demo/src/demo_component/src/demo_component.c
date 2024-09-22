#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "demo_component.h"
//

int demo_component_init()
{
    printf("SYSTEM_NAME: %s\n", CONFIG_SYSTEM_NAME);

    return 0;
}
