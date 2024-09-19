#include <stdio.h>
#include "main.h"


int main()
{
    printf("RibbonDF system name: %s\n", CONFIG_SYSTEM_NAME);
    printf("RibbonDF version: V%d.%d.%d\n", CONFIG_PROJECT_MAJOR_VERSION, CONFIG_PROJECT_MINOR_VERSION, CONFIG_PROJECT_PATCH_VERSION);
    return 0;
}
