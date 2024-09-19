#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "demo_app.h"
#include "demo_component.h"

int main()
{
    printf("DEBUG:%d, TAG:%d\n", DEBUG, TAG);

    demo_component_init();

    return 0;
}
